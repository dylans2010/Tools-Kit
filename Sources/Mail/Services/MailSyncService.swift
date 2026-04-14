import Foundation

class MailSyncService: ObservableObject, @unchecked Sendable {
    static let shared = MailSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let storage = MailStorageService.shared

    func sync(account: MailAccount, folder: MailFolder) async {
        guard !isSyncing else { return }

        DispatchQueue.main.async { self.isSyncing = true }
        print("📬 MailSync: starting sync for \(account.email) folder=\(folder.id)")

        do {
            print("📡 MailSync: connecting to provider…")
            let provider = iCloudMailProvider(account: account)
            let threads = try await provider.fetchThreads(in: folder, limit: 50, offset: 0)
            print("✅ MailSync: fetched \(threads.count) threads")
            storage.saveThreads(threads, for: "\(account.id)_\(folder.id)")
            print("💾 MailSync: saved threads locally")

            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            print("❌ MailSync: failed for \(account.email): \(error)")
            DispatchQueue.main.async { self.isSyncing = false }
        }
    }

    func syncAll(folder: MailFolder = .inbox) async {
        let accounts = storage.loadAccounts()
        for account in accounts where account.isEnabled {
            await sync(account: account, folder: folder)
        }
    }
}
