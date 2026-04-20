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
    private var gmailPageTokensByAccount: [String: [Int: String?]] = [:]

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
        for account in accounts where account.isEnabled {
            await fetchThreads(account: account, folder: folder)
        }
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
            gmailPageTokensByAccount[account.id] = [0: nil]
        }
        activeAccount = account
        activeFolder = folder

        InternalLogger.shared.log("MailSync: starting fetch for \(account.emailAddress) folder=\(folder.id)", level: .info)

        do {
            let groupedThreads: [MailThread]
            let pageNumber = max(0, currentOffset / pageSize)

            switch account.provider {
            case .gmail:
                let accountId = account.id
                let fallbackAccessToken = account.accessToken
                let fallbackRefreshToken = account.refreshToken
                let fallbackEmail = account.emailAddress
                let gmail = GmailService(
                    accountId: accountId,
                    fallbackAccessToken: fallbackAccessToken,
                    fallbackRefreshToken: fallbackRefreshToken,
                    fallbackEmail: fallbackEmail
                )
                let pageToken = gmailPageTokensByAccount[account.id]?[currentOffset] ?? nil
                let page = try await gmail.fetchInbox(maxResults: pageSize, pageToken: pageToken)
                let messageService = gmail
                let messages = try await withThrowingTaskGroup(of: MailMessage.self, returning: [MailMessage].self) { group in
                    for messageRef in page.messages {
                        let messageId = messageRef.id
                        group.addTask {
                            try await messageService.fetchMessage(id: messageId)
                        }
                    }

                    var collected: [MailMessage] = []
                    for try await message in group {
                        collected.append(message)
                    }
                    return collected
                }
                groupedThreads = groupMessages(messages)
                if let nextPageToken = page.nextPageToken {
                    gmailPageTokensByAccount[account.id, default: [0: nil]][currentOffset + pageSize] = nextPageToken
                    hasMorePages = true
                } else {
                    hasMorePages = false
                }
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
            storage.saveThreads(merged, for: folderKey)
            InternalLogger.shared.log("MailSync: storage updated for key \(folderKey)", level: .debug)

            currentOffset += groupedThreads.count
            if account.provider != .gmail {
                hasMorePages = groupedThreads.count == pageSize
            }
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

    private func session(from account: MailAccount) -> MailSession {
        MailSession(
            id: account.id,
            provider: account.provider,
            email: account.emailAddress,
            displayName: account.displayName,
            accessToken: account.accessToken,
            refreshToken: account.refreshToken,
            imapHost: account.imapHost,
            imapPort: account.imapPort,
            smtpHost: account.smtpHost,
            smtpPort: account.smtpPort
        )
    }
}
