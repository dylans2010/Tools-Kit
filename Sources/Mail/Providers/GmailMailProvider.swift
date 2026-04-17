import Foundation

class GmailMailProvider: MailProviderProtocol {
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
        try await imapService.connect(provider: .gmail)
        try await imapService.login(user: account.email, pass: password)

        let messages = try await imapService.fetchMessages(folder: folder.id, limit: limit, offset: offset)
        let grouped = Dictionary(grouping: messages, by: { $0.threadId })

        let threads = grouped.map { (_, groupedMessages) in
            MailThread(
                id: groupedMessages.first?.threadId ?? UUID().uuidString,
                subject: groupedMessages.first?.subject ?? "No Subject",
                messages: groupedMessages.sorted(by: { $0.date < $1.date }),
                lastMessageDate: groupedMessages.map({ $0.date }).max() ?? Date()
            )
        }

        return threads.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    func sendMessage(_ message: MailMessage) async throws {
        guard let password = MailKeychainManager.shared.getPassword(for: account.email) else {
            throw NSError(domain: "MailError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }

        try await smtpService.send(message: message, user: account.email, pass: password, provider: .gmail)
    }

    func markAsRead(_ threadId: String) async throws {}

    func deleteThread(_ threadId: String) async throws {}

    func starThread(_ threadId: String, starred: Bool) async throws {}
}
