import Foundation

class iCloudMailProvider: MailProviderProtocol {
    let account: MailAccount
    private let imapService = MailIMAPService()
    private let smtpService = MailSMTPService()

    init(account: MailAccount) {
        self.account = account
    }

    func fetchFolders() async throws -> [MailFolder] {
        return [.inbox, .sent, .drafts, .starred, .trash]
    }

    func fetchThreads(in folder: MailFolder, limit: Int, offset: Int) async throws -> [MailThread] {
        guard let password = MailKeychainManager.shared.getPassword(for: account.email) else {
            throw NSError(domain: "MailError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }
        defer { imapService.disconnect() }
        try await imapService.connect()
        try await imapService.login(user: account.email, pass: password)
        let messages = try await imapService.fetchMessages(folder: folder.id, limit: limit, offset: offset)

        // Basic grouping into threads by subject for V1
        let grouped = Dictionary(grouping: messages, by: { $0.threadId })
        let threads = grouped.map { (_, messages) in
            MailThread(
                id: messages.first?.threadId ?? UUID().uuidString,
                subject: messages.first?.subject ?? "No Subject",
                messages: messages.sorted(by: { $0.date < $1.date }),
                lastMessageDate: messages.map({ $0.date }).max() ?? Date()
            )
        }
        return threads.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    func sendMessage(_ message: MailMessage) async throws {
        guard let password = MailKeychainManager.shared.getPassword(for: account.email) else {
            throw NSError(domain: "MailError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }
        try await smtpService.send(message: message, user: account.email, pass: password)
    }

    func markAsRead(_ threadId: String) async throws {
        // IMAP STORE +FLAGS (\Seen)
    }

    func deleteThread(_ threadId: String) async throws {
        // IMAP STORE +FLAGS (\Deleted) + EXPUNGE
    }

    func starThread(_ threadId: String, starred: Bool) async throws {
        // IMAP STORE +/-FLAGS (\Flagged)
    }
}
