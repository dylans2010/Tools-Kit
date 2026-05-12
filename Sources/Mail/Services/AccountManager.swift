import Foundation

@MainActor
final class AccountManager: ObservableObject {
    static let shared = AccountManager()

    @Published private(set) var accounts: [MailAccount] = []
    @Published private(set) var activeAccount: MailAccount?

    private init() {
        refreshAccounts()
    }

    func refreshAccounts() {
        MailStore.shared.reloadAccounts()
        accounts = MailStore.shared.accounts
        activeAccount = MailStore.shared.activeAccount
    }

    @discardableResult
    func addAccount(_ session: MailSession, activate: Bool = true) -> MailAccount {
        let account = MailAccount(
            id: session.id,
            emailAddress: session.email,
            providerType: session.provider,
            displayName: session.displayName,
            accessTokenExpiration: session.accessTokenExpiration,
            imapHost: session.imapHost,
            imapPort: session.imapPort,
            smtpHost: session.smtpHost,
            smtpPort: session.smtpPort,
            isActive: activate
        )
        MailStore.shared.addOrUpdateAccount(account, makeActive: activate)
        refreshAccounts()
        return activeAccount ?? account
    }

    func setActiveAccount(_ id: String) {
        MailStore.shared.setActiveAccount(id)
        refreshAccounts()
    }

    func removeAccount(_ account: MailAccount) {
        MailStore.shared.removeAccount(account)
        refreshAccounts()
    }

    func account(for id: String) -> MailAccount? {
        accounts.first(where: { $0.id == id })
    }

    func token(for accountId: String, provider: MailAccount.ProviderType, forceRefresh: Bool = false) async throws -> String {
        guard let account = account(for: accountId), account.providerType == provider else {
            throw NSError(domain: "AccountManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Account/provider mismatch"])
        }

        if !forceRefresh,
           let expiration = account.accessTokenExpiration,
           expiration > Date().addingTimeInterval(120),
           let existing = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.accessToken,
           !existing.isEmpty {
            return existing
        }

        if !forceRefresh,
           let existing = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.accessToken,
           !existing.isEmpty,
           account.accessTokenExpiration == nil {
            return existing
        }

        return try await OAuthManager.shared.refreshToken(for: account)
    }

    func registerAuthenticatedAccount(_ session: MailSession, syncFolder: MailFolder = .inbox) async {
        let account = addAccount(session, activate: true)
        await MailSyncService.shared.fetchThreads(account: account, folder: syncFolder)
    }
}
