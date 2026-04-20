import AuthenticationServices
import CryptoKit
import Foundation

enum GmailAuthError: LocalizedError {
    case invalidRedirectURL
    case missingAuthorizationCode
    case invalidState
    case missingRefreshToken
    case tokenExchangeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRedirectURL:
            return "Invalid Gmail OAuth redirect URL."
        case .missingAuthorizationCode:
            return "Missing authorization code from Gmail OAuth redirect."
        case .invalidState:
            return "OAuth state validation failed."
        case .missingRefreshToken:
            return "Google OAuth did not return a refresh token."
        case .tokenExchangeFailed(let details):
            return details
        }
    }
}

final class GmailAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GmailAuthManager()

    private var authSession: ASWebAuthenticationSession?

    private override init() {}

    func signIn(accountId: String) async throws -> GmailTokenBundle {
        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: GmailModuleConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: GmailModuleConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GmailModuleConfig.oauthScopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]

        guard let authURL = components.url else {
            throw GmailAuthError.invalidRedirectURL
        }

        let callbackURL = try await startOAuth(url: authURL)
        let code = try authorizationCode(from: callbackURL, expectedState: state)
        let exchanged = try await exchangeAuthorizationCode(code: code, verifier: verifier)
        let email = try await fetchProfileEmail(accessToken: exchanged.accessToken)

        let refreshToken = exchanged.refreshToken ?? GmailTokenStore.shared.load(accountId: accountId)?.refreshToken
        guard let refreshToken, !refreshToken.isEmpty else {
            throw GmailAuthError.missingRefreshToken
        }

        let tokens = GmailTokenBundle(
            accessToken: exchanged.accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(exchanged.expiresIn)),
            emailAddress: email
        )

        _ = GmailTokenStore.shared.save(tokens, accountId: accountId)
        return tokens
    }

    func receiveRedirectURL(_ url: URL) -> Bool {
        url.scheme == GmailModuleConfig.redirectScheme && url.path == GmailModuleConfig.redirectPath
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

    private func startOAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: GmailModuleConfig.redirectScheme) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: GmailAuthError.invalidRedirectURL)
                    return
                }
                continuation.resume(returning: callback)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            authSession = session
            _ = session.start()
        }
    }

    private func authorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard callbackURL.scheme == GmailModuleConfig.redirectScheme, callbackURL.path == GmailModuleConfig.redirectPath else {
            throw GmailAuthError.invalidRedirectURL
        }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw GmailAuthError.invalidRedirectURL
        }

        let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == expectedState else {
            throw GmailAuthError.invalidState
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw GmailAuthError.missingAuthorizationCode
        }
        return code
    }

    private func exchangeAuthorizationCode(code: String, verifier: String) async throws -> GmailOAuthTokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let fields = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: GmailModuleConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: GmailModuleConfig.redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]
        request.httpBody = gmailFormURLEncodedBody(fields)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GmailAuthError.tokenExchangeFailed("Token exchange failed.")
        }
        guard (200...299).contains(http.statusCode) else {
            let details = String(data: data, encoding: .utf8) ?? "Token exchange failed."
            throw GmailAuthError.tokenExchangeFailed(details)
        }
        return try JSONDecoder().decode(GmailOAuthTokenResponse.self, from: data)
    }

    private func fetchProfileEmail(accessToken: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/profile")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let details = String(data: data, encoding: .utf8) ?? "Unable to load Gmail profile."
            throw GmailAuthError.tokenExchangeFailed(details)
        }
        return try JSONDecoder().decode(GmailProfileResponse.self, from: data).emailAddress
    }

    private func randomCodeVerifier() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<64).compactMap { _ in chars.randomElement() })
    }

    private func codeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
