import AuthenticationServices
import CryptoKit
import SwiftUI

struct AddMailAccountView: View {
    @Environment(\.dismiss) private var dismiss

    let onAccountSelected: (MailAccount) -> Void

    @StateObject private var mailStore = MailStore.shared
    @State private var selectedProvider: MailAccount.MailProviderType = .gmail
    @State private var email = ""
    @State private var appPassword = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Connect a new account") {
                    providerRow(provider: .gmail, subtitle: "Secure OAuth with Gmail API scopes")
                    providerRow(provider: .iCloud, subtitle: "Use app-specific password")
                    providerRow(provider: .yahoo, subtitle: "Use app password for IMAP/SMTP")
                    providerRow(provider: .outlook, subtitle: "Use app password for IMAP/SMTP")

                    if selectedProvider != .gmail {
                        TextField("\(selectedProvider.displayName) Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        SecureField("App password", text: $appPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        Label("Gmail uses OAuth and never stores your password.", systemImage: "lock.shield")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        addAccount()
                    } label: {
                        HStack {
                            if isWorking {
                                ProgressView().tint(.white)
                            }
                            Text(buttonTitle)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isActionDisabled)
                }

                Section("Saved accounts") {
                    if mailStore.accounts.isEmpty {
                        Text("No mail accounts yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(mailStore.accounts) { account in
                            HStack(spacing: 12) {
                                Image(systemName: providerIcon(for: account.provider))
                                    .foregroundStyle(providerColor(for: account.provider))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(account.emailAddress)
                                        .font(.subheadline.weight(.semibold))
                                    Text(account.provider.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if account.isActive {
                                    Label("Active", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Button("Use") {
                                        mailStore.setActiveAccount(account.id)
                                        onAccountSelected(account)
                                        dismiss()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    mailStore.removeAccount(account)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Mail Account")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            mailStore.reloadAccounts()
        }
    }

    private var buttonTitle: String {
        if isWorking {
            return "Working..."
        }
        return selectedProvider == .gmail ? "Connect Gmail" : "Add \(selectedProvider.displayName)"
    }

    private var isActionDisabled: Bool {
        if isWorking {
            return true
        }
        if selectedProvider == .gmail {
            return false
        }
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appPassword.isEmpty
    }

    @ViewBuilder
    private func providerRow(provider: MailAccount.MailProviderType, subtitle: String) -> some View {
        Button {
            selectedProvider = provider
            errorMessage = nil
        } label: {
            HStack {
                Image(systemName: providerIcon(for: provider))
                    .foregroundStyle(providerColor(for: provider))
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedProvider == provider {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func addAccount() {
        errorMessage = nil
        isWorking = true

        Task {
            do {
                if selectedProvider == .gmail {
                    let oauthResult = try await GmailOAuthService().authorize()
                    let account = MailAccount(
                        emailAddress: oauthResult.email,
                        providerType: .gmail,
                        displayName: oauthResult.displayName ?? "Gmail",
                        accessToken: oauthResult.accessToken,
                        refreshToken: oauthResult.refreshToken,
                        isActive: true
                    )
                    _ = MailKeychainManager.shared.saveOAuthTokens(
                        accountId: account.id,
                        accessToken: oauthResult.accessToken,
                        refreshToken: oauthResult.refreshToken
                    )
                    await MainActor.run {
                        mailStore.addOrUpdateAccount(account, makeActive: true)
                        onAccountSelected(mailStore.activeAccount ?? account)
                        isWorking = false
                        dismiss()
                    }
                    return
                }

                let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard selectedProvider.isValidAddress(normalizedEmail) else {
                    throw NSError(domain: "Mail", code: 400, userInfo: [NSLocalizedDescriptionKey: "Use a valid \(selectedProvider.displayName) email address."])
                }

                let imap = MailIMAPService()
                try await imap.connect(provider: selectedProvider)
                defer { imap.disconnect() }
                try await imap.login(user: normalizedEmail, pass: appPassword)

                guard MailKeychainManager.shared.saveCredentials(email: normalizedEmail, password: appPassword) else {
                    throw NSError(domain: "Mail", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to save credentials to Keychain"])
                }

                let account = MailAccount(
                    emailAddress: normalizedEmail,
                    providerType: selectedProvider,
                    displayName: selectedProvider.displayName,
                    isActive: true
                )

                await MainActor.run {
                    mailStore.addOrUpdateAccount(account, makeActive: true)
                    onAccountSelected(mailStore.activeAccount ?? account)
                    isWorking = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
                InternalLogger.shared.log("AddMailAccountView: failed to add account - \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func providerIcon(for provider: MailAccount.MailProviderType) -> String {
        switch provider {
        case .icloud:
            return "icloud.fill"
        case .gmail:
            return "envelope.fill"
        case .yahoo:
            return "y.circle.fill"
        case .outlook:
            return "o.circle.fill"
        }
    }

    private func providerColor(for provider: MailAccount.MailProviderType) -> Color {
        switch provider {
        case .icloud:
            return .blue
        case .gmail:
            return .red
        case .yahoo:
            return .purple
        case .outlook:
            return .indigo
        }
    }
}

private struct GmailOAuthResult {
    let accessToken: String
    let refreshToken: String?
    let email: String
    let displayName: String?
}

private final class GmailOAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    private static let scopes = [
        "openid",
        "email",
        "profile",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.send",
        "https://www.googleapis.com/auth/gmail.modify"
    ]

    func authorize() async throws -> GmailOAuthResult {
        let oauthConfig = try await MailOAuthConfigService.shared.resolvedConfig()
        let clientID = oauthConfig.clientID
        let redirectURI = oauthConfig.redirectURI

        let verifier = Self.randomCodeVerifier()
        let challenge = Self.codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "GmailOAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to build Google OAuth URL"])
        }

        InternalLogger.shared.log("GmailOAuth: launching Google OAuth web session", level: .info)
        let callbackURL = try await startWebAuth(url: authURL, callbackScheme: URL(string: redirectURI)?.scheme)
        guard let returnedState = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "state" })?.value,
              returnedState == state else {
            throw NSError(domain: "GmailOAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "OAuth state validation failed"])
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "GmailOAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing OAuth authorization code"])
        }

        let tokenResponse = try await exchangeCodeForToken(
            code: code,
            verifier: verifier,
            clientID: clientID,
            redirectURI: redirectURI
        )

        let profile = try await fetchProfile(accessToken: tokenResponse.accessToken)
        InternalLogger.shared.log("GmailOAuth: account connected for \(profile.email)", level: .info)

        return GmailOAuthResult(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            email: profile.email,
            displayName: profile.name
        )
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

    private func startWebAuth(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: NSError(domain: "GmailOAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: "OAuth callback URL missing"]))
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            authSession.prefersEphemeralWebBrowserSession = true
            authSession.presentationContextProvider = self
            self.session = authSession
            _ = authSession.start()
        }
    }

    private func exchangeCodeForToken(code: String, verifier: String, clientID: String, redirectURI: String) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let items = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]

        request.httpBody = items
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "OAuth token exchange failed"
            throw NSError(domain: "GmailOAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: message])
        }

        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }

    private func fetchProfile(accessToken: String) async throws -> GoogleProfileResponse {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Failed to fetch Google profile"
            throw NSError(domain: "GmailOAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(GoogleProfileResponse.self, from: data)
    }

    private static func randomCodeVerifier() -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<64).compactMap { _ in charset.randomElement() })
    }

    private static func codeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let data = Data(digest)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct GoogleProfileResponse: Decodable {
    let email: String
    let name: String?
}

struct MailOAuthConfig {
    let clientID: String
    let redirectURI: String
}

enum MailOAuthConfigError: LocalizedError {
    case missingClientID
    case missingRedirectURI

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing GOOGLE_OAUTH_CLIENT_ID (Appwrite global vars or Config.plist)"
        case .missingRedirectURI:
            return "Missing GOOGLE_OAUTH_REDIRECT_URI (Appwrite global vars or Config.plist)"
        }
    }
}

actor MailOAuthConfigService {
    static let shared = MailOAuthConfigService()

    private var cachedConfig: MailOAuthConfig?

    func resolvedConfig() async throws -> MailOAuthConfig {
        if let cachedConfig {
            return cachedConfig
        }

        let remote = await fetchRemoteVariables()

        let clientID = firstNonEmpty([
            remote["GOOGLE_OAUTH_CLIENT_ID"],
            remote["GOOGLE_WEB_CLIENT_ID"],
            Self.localConfigValue(forKey: "GOOGLE_OAUTH_CLIENT_ID")
        ])

        let redirectURI = firstNonEmpty([
            remote["GOOGLE_OAUTH_REDIRECT_URI"],
            remote["GOOGLE_WEB_REDIRECT_URI"],
            Self.localConfigValue(forKey: "GOOGLE_OAUTH_REDIRECT_URI")
        ])

        guard let clientID else {
            throw MailOAuthConfigError.missingClientID
        }
        guard let redirectURI else {
            throw MailOAuthConfigError.missingRedirectURI
        }

        let resolved = MailOAuthConfig(clientID: clientID, redirectURI: redirectURI)
        cachedConfig = resolved
        return resolved
    }

    func clearCache() {
        cachedConfig = nil
    }

    private func fetchRemoteVariables() async -> [String: String] {
        guard
            let rawURL = Self.localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_URL"),
            let url = URL(string: rawURL)
        else {
            return [:]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearer = Self.localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_BEARER") {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return [:]
            }

            if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
                return direct
            }

            if let wrapped = try? JSONDecoder().decode(AppwriteVariableEnvelope.self, from: data) {
                var parsed: [String: String] = [:]
                for item in wrapped.variables {
                    parsed[item.key] = item.value
                }
                for (key, value) in wrapped.data {
                    parsed[key] = value
                }
                return parsed
            }

            return [:]
        } catch {
            return [:]
        }
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            guard let value else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private static func localConfigValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String
        else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct AppwriteVariableEnvelope: Decodable {
    let variables: [VariableItem]
    let data: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.variables = (try? container.decode([VariableItem].self, forKey: .variables)) ?? []
        self.data = (try? container.decode([String: String].self, forKey: .data)) ?? [:]
    }

    private enum CodingKeys: String, CodingKey {
        case variables
        case data
    }
}

private struct VariableItem: Decodable {
    let key: String
    let value: String
}

#Preview {
    AddMailAccountView(onAccountSelected: { _ in })
}
