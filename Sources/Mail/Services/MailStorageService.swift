import Foundation

class MailStorageService: ObservableObject {
    static let shared = MailStorageService()
    private let fileManager = FileManager.default
    @Published var threads: [MailThread] = []
    private var activeFolderId: String?

    private var baseDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mailDir = docs.appendingPathComponent("Workspace/Mail", isDirectory: true)
        if !fileManager.fileExists(atPath: mailDir.path) {
            try? fileManager.createDirectory(at: mailDir, withIntermediateDirectories: true)
        }
        return mailDir
    }

    func saveThreads(_ threads: [MailThread], for folderId: String) {
        let fileURL = baseDirectory.appendingPathComponent("threads_\(folderId).json")
        do {
            let data = try JSONEncoder().encode(threads)
            try data.write(to: fileURL)
            activeFolderId = folderId
            DispatchQueue.main.async {
                self.threads = threads
            }
        } catch {
            print("Failed to save threads: \(error)")
        }
    }

    func loadThreads(for folderId: String) -> [MailThread] {
        let fileURL = baseDirectory.appendingPathComponent("threads_\(folderId).json")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            activeFolderId = folderId
            DispatchQueue.main.async { self.threads = [] }
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([MailThread].self, from: data)
            activeFolderId = folderId
            DispatchQueue.main.async {
                self.threads = decoded
            }
            return decoded
        } catch {
            print("Failed to load threads: \(error)")
            return []
        }
    }

    func saveAccounts(_ accounts: [MailAccount]) {
        let fileURL = baseDirectory.appendingPathComponent("accounts.json")
        do {
            let data = try JSONEncoder().encode(accounts)
            try data.write(to: fileURL)
            InternalLogger.shared.log("MailStorage: saved \(accounts.count) accounts", level: .debug)
        } catch {
            InternalLogger.shared.log("MailStorage: failed to save accounts - \(error.localizedDescription)", level: .error)
        }
    }

    func loadAccounts() -> [MailAccount] {
        let fileURL = baseDirectory.appendingPathComponent("accounts.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([MailAccount].self, from: data)
        } catch {
            InternalLogger.shared.log("MailStorage: failed to load accounts - \(error.localizedDescription)", level: .error)
            return []
        }
    }
}

@MainActor
final class MailStore: ObservableObject {
    static let shared = MailStore()

    @Published private(set) var accounts: [MailAccount] = []
    @Published private(set) var activeAccount: MailAccount?

    private let storage = MailStorageService.shared

    private init() {
        reloadAccounts()
    }

    func reloadAccounts() {
        var loaded = storage.loadAccounts()

        // Hydrate sensitive OAuth tokens from Keychain only.
        for idx in loaded.indices {
            if let tokens = MailKeychainManager.shared.getOAuthTokens(accountId: loaded[idx].id) {
                loaded[idx].accessToken = tokens.accessToken
                loaded[idx].refreshToken = tokens.refreshToken
            }
        }

        if let selected = loaded.first(where: { $0.isActive }) {
            activeAccount = selected
        } else {
            activeAccount = loaded.first
            if !loaded.isEmpty {
                for idx in loaded.indices {
                    loaded[idx].isActive = loaded[idx].id == activeAccount?.id
                }
            }
        }

        accounts = loaded
        persistAccounts()
        InternalLogger.shared.log("MailStore: loaded \(accounts.count) account(s)", level: .info)
    }

    func addOrUpdateAccount(_ account: MailAccount, makeActive: Bool = true) {
        var incoming = account
        if incoming.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            incoming.displayName = incoming.providerType.displayName
        }

        if let token = incoming.accessToken, !token.isEmpty {
            _ = MailKeychainManager.shared.saveOAuthTokens(accountId: incoming.id, accessToken: token, refreshToken: incoming.refreshToken)
        }

        if let existing = accounts.firstIndex(where: { $0.id == incoming.id || $0.emailAddress.caseInsensitiveCompare(incoming.emailAddress) == .orderedSame }) {
            let existingId = accounts[existing].id
            let mergedAccount = MailAccount(
                id: existingId,
                emailAddress: incoming.emailAddress,
                providerType: incoming.providerType,
                displayName: incoming.displayName,
                accessToken: incoming.accessToken,
                refreshToken: incoming.refreshToken,
                isActive: incoming.isActive
            )
            accounts[existing] = mergedAccount
            incoming = mergedAccount
        } else {
            accounts.append(incoming)
        }

        if makeActive {
            setActiveAccount(incoming.id)
        } else {
            persistAccounts()
        }

        InternalLogger.shared.log("MailStore: account saved for \(incoming.emailAddress)", level: .info)
    }

    func setActiveAccount(_ accountId: String) {
        guard accounts.contains(where: { $0.id == accountId }) else { return }
        for idx in accounts.indices {
            accounts[idx].isActive = accounts[idx].id == accountId
        }
        activeAccount = accounts.first(where: { $0.id == accountId })
        persistAccounts()
        if let activeAccount {
            InternalLogger.shared.log("MailStore: active account switched to \(activeAccount.emailAddress)", level: .info)
        }
    }

    func updateAccountTokens(accountId: String, accessToken: String, refreshToken: String?) {
        guard let idx = accounts.firstIndex(where: { $0.id == accountId }) else { return }
        accounts[idx].accessToken = accessToken
        if let refreshToken {
            accounts[idx].refreshToken = refreshToken
        }

        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: accountId, accessToken: accessToken, refreshToken: refreshToken ?? accounts[idx].refreshToken)
        persistAccounts()
        InternalLogger.shared.log("MailStore: OAuth tokens updated for \(accounts[idx].emailAddress)", level: .debug)
    }

    func removeAccount(_ account: MailAccount) {
        MailKeychainManager.shared.deleteCredentials(for: account.emailAddress)
        MailKeychainManager.shared.deleteOAuthTokens(accountId: account.id)

        accounts.removeAll { $0.id == account.id }
        if activeAccount?.id == account.id {
            activeAccount = accounts.first
            if let replacement = activeAccount {
                for idx in accounts.indices {
                    accounts[idx].isActive = accounts[idx].id == replacement.id
                }
            }
        }

        persistAccounts()
        InternalLogger.shared.log("MailStore: account removed for \(account.emailAddress)", level: .warning)
    }

    private func persistAccounts() {
        let sanitized = accounts.map { account -> MailAccount in
            var copy = account
            copy.accessToken = nil
            copy.refreshToken = nil
            return copy
        }
        storage.saveAccounts(sanitized)
    }
}
