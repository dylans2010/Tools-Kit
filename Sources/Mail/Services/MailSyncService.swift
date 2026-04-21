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
    private var hasMorePages = true
    private var activeAccount: MailAccount?
    private var activeFolder: MailFolder = .inbox
    private var gmailProviders: [String: GmailMailProvider] = [:]
    private var nextEligibleSyncDate: Date = .distantPast

    func fetchThreads(account: MailAccount, folder: MailFolder) async {
        await performFetch(account: account, folder: folder, reset: true)
    }

    func fetchNextPage() async {
        guard let account = activeAccount else { return }
        guard hasMorePages else { return }
        await performFetch(account: account, folder: activeFolder, reset: false)
    }

    func syncAll(folder: MailFolder = .inbox) async {
        guard MailRuntimeSettings.autoSyncEnabled else { return }
        guard Date() >= nextEligibleSyncDate else { return }
        let accounts = storage.loadAccounts()
        for account in accounts where account.isEnabled {
            await fetchThreads(account: account, folder: folder)
        }
        configureFromSettings()
    }

    func configureFromSettings() {
        let interval = MailRuntimeSettings.syncInterval
        nextEligibleSyncDate = interval.isInfinite ? .distantFuture : Date().addingTimeInterval(interval)
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
            let merged = mergeThreads(existing: reset ? [] : storage.threads, new: groupedThreads)
            let organized = applyFolderRules(to: merged)
            storage.saveThreads(organized, for: folderKey)
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

    private func applyFolderRules(to threads: [MailThread]) -> [MailThread] {
        var updated = threads
        if MailRuntimeSettings.autoSortEnabled {
            updated.sort { $0.lastMessageDate > $1.lastMessageDate }
        }
        return updated
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
