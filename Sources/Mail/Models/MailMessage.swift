import Foundation

struct MailMessage: Identifiable, Codable, Hashable, Sendable {
    let id: String // IMAP UID or message ID
    let threadId: String
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let subject: String
    let body: String
    let htmlBody: String?
    let date: Date
    var isRead: Bool
    var isStarred: Bool
    let attachments: [MailAttachment]

    struct MailAttachment: Identifiable, Codable, Hashable, Sendable {
        let id: String
        let fileName: String
        let contentType: String
        let size: Int64
    }
}
