import Foundation

class MailSyncService: ObservableObject, @unchecked Sendable {
    static let shared = MailSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let storage = MailStorageService.shared

    func sync(account: MailAccount, folder: MailFolder) async {
        guard !isSyncing else { return }

        DispatchQueue.main.async { self.isSyncing = true }

        do {
            let provider = iCloudMailProvider(account: account)
            let threads = try await provider.fetchThreads(in: folder, limit: 50, offset: 0)
            storage.saveThreads(threads, for: folder.id)

            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            print("Sync failed: \(error)")
            DispatchQueue.main.async { self.isSyncing = false }
        }
    }
}
