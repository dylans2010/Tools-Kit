import Foundation

class MailSyncService: ObservableObject, @unchecked Sendable {
    static let shared = MailSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let imapService = MailIMAPService()
    private let storage = MailStorageService.shared
    private let pageSize = 50
    private var currentOffset = 0
    private var activeAccount: MailAccount?
    private var activeFolder: MailFolder = .inbox

    func fetchThreads(account: MailAccount, folder: MailFolder) async {
        await performFetch(account: account, folder: folder, reset: true)
    }

    func fetchNextPage() async {
        guard let account = activeAccount else { return }
        await performFetch(account: account, folder: activeFolder, reset: false)
    }

    func syncAll(folder: MailFolder = .inbox) async {
        let accounts = storage.loadAccounts()
        for account in accounts where account.isEnabled {
            await fetchThreads(account: account, folder: folder)
        }
    }

    // MARK: - Private

    private func performFetch(account: MailAccount, folder: MailFolder, reset: Bool) async {
        guard !isSyncing else { return }

        DispatchQueue.main.async { self.isSyncing = true }
        if reset { currentOffset = 0 }
        activeAccount = account
        activeFolder = folder

        print("[MailSync] Starting IMAP fetch...")

        do {
            defer { imapService.disconnect() }
            guard let password = MailKeychainManager.shared.getPassword(for: account.email) else {
                throw NSError(domain: "MailSync", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
            }

            try await imapService.connect()
            print("[MailSync] IMAP connected. Fetching UIDs...")
            try await imapService.login(user: account.email, pass: password)

            let messages = try await imapService.fetchMessages(folder: folder.id, limit: pageSize, offset: currentOffset)
            print("[MailSync] UIDs received: \(messages.count)")

            let groupedThreads = groupMessages(messages)
            print("[MailSync] Threads parsed: \(groupedThreads.count)")

            let folderKey = "\(account.id)_\(folder.id)"
            let merged = mergeThreads(existing: reset ? [] : storage.threads, new: groupedThreads)
            storage.saveThreads(merged, for: folderKey)
            print("[MailSync] Storage updated. InboxView should refresh.")

            currentOffset += messages.count
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            print("❌ MailSync: failed for \(account.email): \(error)")
            DispatchQueue.main.async { self.isSyncing = false }
        }
    }

    private func groupMessages(_ messages: [MailMessage]) -> [MailThread] {
        let grouped = Dictionary(grouping: messages, by: { $0.threadId })
        return grouped.map { (_, msgs) in
            MailThread(
                id: msgs.first?.threadId ?? UUID().uuidString,
                subject: msgs.first?.subject ?? "No Subject",
                messages: msgs.sorted(by: { $0.date < $1.date }),
                lastMessageDate: msgs.map(\.date).max() ?? Date()
            )
        }
        .sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    private func mergeThreads(existing: [MailThread], new: [MailThread]) -> [MailThread] {
        var combined: [String: MailThread] = [:]
        for thread in existing {
            combined[thread.id] = thread
        }
        for thread in new {
            if let existing = combined[thread.id] {
                var mergedMessages = existing.messages
                for message in thread.messages where !mergedMessages.contains(where: { $0.id == message.id }) {
                    mergedMessages.append(message)
                }
                mergedMessages.sort { $0.date < $1.date }
                combined[thread.id] = MailThread(
                    id: thread.id,
                    subject: thread.subject,
                    messages: mergedMessages,
                    lastMessageDate: mergedMessages.map(\.date).max() ?? thread.lastMessageDate
                )
            } else {
                combined[thread.id] = thread
            }
        }
        return combined.values.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }
}
