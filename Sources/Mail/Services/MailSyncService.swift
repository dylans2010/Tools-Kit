import Foundation

class MailSyncService: ObservableObject, @unchecked Sendable {
    static let shared = MailSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var lastError: String?

    private let imapService = MailIMAPService()
    private let storage = MailStorageService.shared
    private let pageSize = 50
    private var currentOffset = 0
    private var syncTimer: Timer?
    private var hasMorePages = true
    private var activeAccount: MailAccount?
    private var activeFolder: MailFolder = .inbox
    private var gmailProviders: [String: GmailMailProvider] = [:]

    func fetchThreads(account: MailAccount, folder: MailFolder) async {
        await performFetch(account: account, folder: folder, reset: true)
    }

    func fetchNextPage() async {
        guard let account = activeAccount else { return }
        guard hasMorePages else { return }
        await performFetch(account: account, folder: activeFolder, reset: false)
    }

    func syncAll(folder: MailFolder = .inbox) async {
        let accounts = storage.loadAccounts()
        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask {
                    await self.fetchThreads(account: account, folder: folder)
                }
            }
        }
    }

    /// Triggers an initial sync for all accounts, typically called at app startup.
    func performInitialSync() {
        Task {
            await syncAll()
        }
    }

    func startAutoSync() {
        stopAutoSync()
        guard UserDefaults.standard.bool(forKey: "mail.settings.autoSync") else { return }

        let intervalString = UserDefaults.standard.string(forKey: "mail.settings.syncInterval") ?? "15 min"
        let seconds: TimeInterval
        switch intervalString {
        case "5 min": seconds = 5 * 60
        case "15 min": seconds = 15 * 60
        default: return // Manual or unknown
        }

        syncTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.syncAll()
            }
        }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Private

    private func performFetch(account: MailAccount, folder: MailFolder, reset: Bool) async {
        guard !isSyncing else { return }

        await MainActor.run {
            self.isSyncing = true
            self.lastError = nil
        }
        if reset {
            currentOffset = 0
            hasMorePages = true
        }
        activeAccount = account
        activeFolder = folder

        InternalLogger.shared.log("MailSync: starting fetch for \(account.emailAddress) folder=\(folder.id)", level: .info)

        do {
            let groupedThreads: [MailThread]
            let pageNumber = max(0, currentOffset / pageSize)

            switch account.provider {
            case .gmail:
                let provider = await GmailProvider()
                let messages = try await provider.fetchInbox(session: session(from: account), page: pageNumber)
                groupedThreads = groupMessages(messages)
            case .outlook:
                let provider = await OutlookProvider()
                let messages = try await provider.fetchInbox(session: session(from: account), page: pageNumber)
                groupedThreads = groupMessages(messages)
            case .yahoo:
                let provider = await YahooMailProvider()
                let messages = try await provider.fetchInbox(session: session(from: account), page: pageNumber)
                groupedThreads = groupMessages(messages)
            case .proton:
                let provider = ProtonMailProvider()
                let messages = try await provider.fetchInbox(session: session(from: account), page: pageNumber)
                groupedThreads = groupMessages(messages)
            case .imap:
                let provider = IMAPProvider()
                let messages = try await provider.fetchInbox(session: session(from: account), page: pageNumber)
                groupedThreads = groupMessages(messages)
            case .icloud:
                defer { imapService.disconnect() }
                guard let password = MailKeychainManager.shared.getPassword(for: account.emailAddress) else {
                    throw NSError(domain: "MailSync", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
                }

                try await imapService.connect(provider: account.provider)
                try await imapService.login(user: account.emailAddress, pass: password)
                let messages = try await imapService.fetchMessages(folder: folder.id, limit: pageSize, offset: currentOffset)
                groupedThreads = groupMessages(messages)
            }

            InternalLogger.shared.log("MailSync: fetched \(groupedThreads.count) thread(s) for \(account.emailAddress)", level: .debug)

            let folderKey = "\(account.id)_\(folder.id)"
            let processedThreads = applyFolderRules(to: groupedThreads, account: account)
            let merged = mergeThreads(existing: reset ? [] : storage.threads, new: processedThreads)
            storage.saveThreads(merged, for: folderKey)
            InternalLogger.shared.log("MailSync: storage updated for key \(folderKey)", level: .debug)

            currentOffset += groupedThreads.count
            hasMorePages = groupedThreads.count == pageSize
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            InternalLogger.shared.log("MailSync: failed for \(account.emailAddress) - \(error.localizedDescription)", level: .error)
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isSyncing = false
            }
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

    private func applyFolderRules(to threads: [MailThread], account: MailAccount) -> [MailThread] {
        let autoSort = UserDefaults.standard.bool(forKey: "mail.settings.autoSortEmails")
        let autoMarkImportant = UserDefaults.standard.bool(forKey: "mail.settings.autoMarkImportant")

        if !autoSort && !autoMarkImportant { return threads }

        return threads.map { thread in
            var updatedThread = thread
            let subject = thread.subject.lowercased()
            let participants = thread.participants.joined(separator: " ").lowercased()

            // Logic for auto-marking important
            if autoMarkImportant {
                let urgentKeywords = ["urgent", "asap", "deadline", "important", "action required"]
                let isUrgent = urgentKeywords.contains { subject.contains($0) }
                if isUrgent {
                    // In a real system, we'd update the database/server.
                    // Here we're just tagging the local model if possible.
                    // MailThread doesn't have an isImportant field, but it has messages which have isStarred.
                    updatedThread.messages = thread.messages.map { msg in
                        var m = msg
                        m.isStarred = true
                        return m
                    }
                }
            }

            return updatedThread
        }
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

    private func session(from account: MailAccount) -> MailSession {
        MailSession(
            id: account.id,
            provider: account.provider,
            email: account.emailAddress,
            displayName: account.displayName,
            accessTokenExpiration: account.accessTokenExpiration,
            imapHost: account.imapHost,
            imapPort: account.imapPort,
            smtpHost: account.smtpHost,
            smtpPort: account.smtpPort
        )
    }
}
