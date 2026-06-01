import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class GoogleOAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleOAuthManager()

    private var authSession: ASWebAuthenticationSession?

    private let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
    private let authURL = URL(string: "https://accounts.google.com/o/oauth2/auth")!

    private let mandatoryScopes = [
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.send",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile",
        "openid"
    ]

    private override init() {
        super.init()
    }

    func authenticate() async throws -> MailSession {
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try googleClientID(remoteVariables: remoteVariables)
        let redirectURI = try oauthValue(primaryKey: "GOOGLE_OAUTH_REDIRECT_URI", remoteVariables: remoteVariables)
        try validateRedirectURI(redirectURI, clientID: clientID)

        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: mandatoryScopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to build OAuth URL"])
        }

        InternalLogger.shared.log("GoogleOAuth: Starting authentication flow", level: .info)

        let callbackURL = try await startASWebAuthSession(url: url, callbackScheme: URL(string: redirectURI)?.scheme)

        let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "GoogleOAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code in callback"])
        }

        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else {
            throw NSError(domain: "GoogleOAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth state"])
        }

        InternalLogger.shared.log("GoogleOAuth: Exchanging code for tokens", level: .info)
        let tokenResponse = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)

        let profile = try await fetchProfile(accessToken: tokenResponse.accessToken)

        let expirationDate = tokenResponse.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }

        InternalLogger.shared.log("GoogleOAuth: Authentication successful for \(profile.email). Expiration: \(expirationDate?.description ?? "none")", level: .info)

        let sessionID = UUID().uuidString
        let saveResult = MailKeychainManager.shared.saveOAuthTokens(
            accountId: sessionID,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken
        )
        guard saveResult else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to store OAuth tokens in keychain"])
        }

        InternalLogger.shared.log("GoogleOAuth: Stored OAuth tokens for account session \(sessionID)", level: .info)

        return MailSession(
            id: sessionID,
            provider: .gmail,
            email: profile.email,
            displayName: profile.name ?? "Gmail",
            accessTokenExpiration: expirationDate
        )
    }

    func getValidAccessToken(for accountID: String) async throws -> String {
        // 1. Try to find the account in MailStore to check expiration
        let account = await MainActor.run {
            MailStore.shared.accounts.first(where: { $0.id == accountID })
        }

        // 2. Fetch tokens from Keychain
        guard let tokens = MailKeychainManager.shared.getOAuthTokens(accountId: accountID) else {
            throw NSError(domain: "GoogleOAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No tokens found for account \(accountID)"])
        }

        // 3. Check expiration (if we have it)
        if let expiration = account?.accessTokenExpiration {
            // Buffer of 2 minutes to be safe
            if expiration > Date().addingTimeInterval(120) {
                return tokens.accessToken
            }
            InternalLogger.shared.log("GoogleOAuth: Token expired or near expiration for \(accountID), refreshing...", level: .info)
        } else {
            InternalLogger.shared.log("GoogleOAuth: No expiration known for \(accountID), checking validity via refresh", level: .info)
        }

        // 4. Refresh if needed
        guard let refreshToken = tokens.refreshToken else {
            throw NSError(domain: "GoogleOAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available for account \(accountID)"])
        }

        let result = try await refreshAccessToken(for: accountID, refreshToken: refreshToken)
        return result.accessToken
    }

    func refreshAccessToken(for accountID: String, refreshToken: String) async throws -> (accessToken: String, expiration: Date?) {
        InternalLogger.shared.log("GoogleOAuth: Refreshing access token for account \(accountID)", level: .info)

        let remoteVariables = await fetchRemoteVariables()
        let clientID = try googleClientID(remoteVariables: remoteVariables)

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]

        request.httpBody = bodyItems
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            InternalLogger.shared.log("GoogleOAuth: Token refresh failed - \(errorMsg)", level: .error)
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Token refresh failed: \(errorMsg)"])
        }

        let refreshed = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

        // Validate scopes in refresh if returned (though Google often doesn't return them in refresh)
        if let returnedScopes = refreshed.scope {
            try validateScopes(returnedScopes)
        }

        let expirationDate = refreshed.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }

        InternalLogger.shared.log("GoogleOAuth: Token refresh successful. New expiration: \(expirationDate?.description ?? "none")", level: .info)

        // Update storage
        let resolvedRefresh = refreshed.refreshToken ?? refreshToken
        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: accountID, accessToken: refreshed.accessToken, refreshToken: resolvedRefresh)

        await MainActor.run {
            MailStore.shared.updateAccountTokens(
                accountId: accountID,
                accessToken: refreshed.accessToken,
                refreshToken: resolvedRefresh,
                expiration: expirationDate
            )
        }

        return (refreshed.accessToken, expirationDate)
    }

    // MARK: - Private Helpers

    private func startASWebAuthSession(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing callback URL"]))
                    return
                }
                continuation.resume(returning: callback)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            self.authSession = session
            _ = session.start()
        }
    }

    private func exchangeCode(code: String, verifier: String, clientID: String, redirectURI: String) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]

        request.httpBody = bodyItems
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Token exchange failed: \(errorMsg)"])
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

        // Validation
        guard !tokenResponse.accessToken.isEmpty else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Token exchange returned empty access token"])
        }

        guard let refreshToken = tokenResponse.refreshToken, !refreshToken.isEmpty else {
             throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Token exchange did not return a refresh token. Ensure 'access_type=offline' and 'prompt=consent' were used."])
        }

        guard let tokenType = tokenResponse.tokenType, tokenType.caseInsensitiveCompare("Bearer") == .orderedSame else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unsupported token type: \(tokenResponse.tokenType ?? "nil")"])
        }

        // Scope validation
        if let returnedScopes = tokenResponse.scope {
            try validateScopes(returnedScopes)
        } else {
            InternalLogger.shared.log("GoogleOAuth: WARNING - No scope field in token response. Skipping validation.", level: .warning)
        }

        return tokenResponse
    }

    private func validateScopes(_ scopeString: String) throws {
        let grantedScopes = Set(scopeString.components(separatedBy: " ").filter { !$0.isEmpty })
        InternalLogger.shared.log("GoogleOAuth: Validating granted scopes: \(grantedScopes)", level: .info)

        let missing = mandatoryScopes.filter { !grantedScopes.contains($0) }
        if !missing.isEmpty {
            InternalLogger.shared.log("GoogleOAuth: ERROR - Missing mandatory scopes: \(missing)", level: .error)
            throw NSError(domain: "GoogleOAuthManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "User did not grant all required permissions: \(missing.joined(separator: ", "))"])
        }
    }

    private func fetchProfile(accessToken: String) async throws -> GoogleProfile {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user profile"])
        }

        return try JSONDecoder().decode(GoogleProfile.self, from: data)
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

    // MARK: - PKCE
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

    // MARK: - Config Helpers
    private func oauthValue(primaryKey: String, fallbackKey: String? = nil, remoteVariables: [String: String] = [:]) throws -> String {
        if let value = localConfigValue(forKey: primaryKey) { return value }
        if let value = AppConfig.string(for: primaryKey) { return value }
        if let value = remoteVariables[primaryKey]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty { return value }

        if let fallbackKey {
            if let value = localConfigValue(forKey: fallbackKey) { return value }
            if let value = AppConfig.string(for: fallbackKey) { return value }
            if let value = remoteVariables[fallbackKey]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty { return value }
        }

        throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing config key: \(primaryKey)"])
    }

    private func googleClientID(remoteVariables: [String: String]) throws -> String {
        try oauthValue(primaryKey: "GOOGLE_CLIENT_ID", remoteVariables: remoteVariables)
    }

    private func localConfigValue(forKey key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func fetchRemoteVariables() async -> [String: String] {
        guard let rawURL = localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_URL"),
              let url = URL(string: rawURL) else { return [:] }

        var request = URLRequest(url: url)
        if let bearer = localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_BEARER") {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return [:]
            }
            return decodeRemoteVariables(from: data)
        } catch {
            return [:]
        }
    }

    private func decodeRemoteVariables(from data: Data) -> [String: String] {
        if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
            return direct
                .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.value.isEmpty }
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }

        var values: [String: String] = [:]
        collectRemoteVariables(from: object, into: &values, parentKey: nil)
        return values
            .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.value.isEmpty }
    }

    private func collectRemoteVariables(from object: Any, into output: inout [String: String], parentKey: String?) {
        switch object {
        case let dictionary as [String: Any]:
            if let key = dictionary["key"] as? String, let value = dictionary["value"] as? String {
                output[key] = value
            }
            if let parentKey, let value = dictionary["value"] as? String, looksLikeConfigKey(parentKey) {
                output[parentKey] = value
            }

            for (key, value) in dictionary {
                if let stringValue = value as? String, looksLikeConfigKey(key) {
                    output[key] = stringValue
                }
                collectRemoteVariables(from: value, into: &output, parentKey: key)
            }
        case let array as [Any]:
            for item in array {
                collectRemoteVariables(from: item, into: &output, parentKey: parentKey)
            }
        default:
            break
        }
    }

    private func looksLikeConfigKey(_ key: String) -> Bool {
        guard key.range(of: #"^[A-Z][A-Z0-9_]*$"#, options: .regularExpression) != nil else { return false }
        let allowedPrefixes = ["APPWRITE_", "GOOGLE_", "GMAIL_", "PRODUCTION_", "DAILY_", "MAIL_", "OUTLOOK_", "YAHOO_"]
        return allowedPrefixes.contains { key.hasPrefix($0) }
    }

    private func validateRedirectURI(_ redirectURI: String, clientID: String) throws {
        guard let components = URLComponents(string: redirectURI),
              let scheme = components.scheme?.lowercased(),
              components.path == "/oauthredirect" else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid redirect URI path"])
        }

        let expectedPrefix = "com.googleusercontent.apps."
        guard scheme.hasPrefix(expectedPrefix) else {
            throw NSError(domain: "GoogleOAuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Redirect URI must use native Google iOS format"])
        }
    }
}

private struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }
}

private struct GoogleProfile: Decodable {
    let email: String
    let name: String?
}
