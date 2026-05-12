import AuthenticationServices
import Foundation

@MainActor
final class OAuthManager {
    static let shared = OAuthManager()

    private init() {}

    func authenticate(provider: MailAccount.ProviderType) async throws -> MailSession {
        switch provider {
        case .outlook:
            return try await OutlookProvider().authenticate(credentials: .oauth())
        case .yahoo:
            return try await YahooMailProvider().authenticate(credentials: .oauth())
        case .gmail:
            return try await GoogleOAuthManager.shared.authenticate()
        case .proton, .imap, .icloud:
            throw NSError(domain: "OAuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "OAuth not supported for \(provider.displayName)"])
        }
    }

    @discardableResult
    func refreshToken(for account: MailAccount) async throws -> String {
        let session = MailSession(
            id: account.id,
            provider: account.providerType,
            email: account.emailAddress,
            displayName: account.displayName,
            accessTokenExpiration: account.accessTokenExpiration,
            imapHost: account.imapHost,
            imapPort: account.imapPort,
            smtpHost: account.smtpHost,
            smtpPort: account.smtpPort
        )

        switch account.providerType {
        case .outlook:
            _ = try await OutlookProvider().refreshSessionToken(session: session)
        case .yahoo:
            _ = try await YahooMailProvider().refreshSessionToken(session: session)
        case .gmail:
            guard let refresh = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.refreshToken else {
                throw NSError(domain: "OAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing refresh token for Gmail account"])
            }
            let refreshed = try await GoogleOAuthManager.shared.refreshAccessToken(for: account.id, refreshToken: refresh)
            return refreshed.accessToken
        case .proton, .imap, .icloud:
            throw NSError(domain: "OAuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Token refresh not supported for \(account.providerType.displayName)"])
        }

        guard let access = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.accessToken else {
            throw NSError(domain: "OAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No valid access token after refresh"])
        }
        return access
    }
}
