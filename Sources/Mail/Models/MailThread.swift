import Foundation

struct MailThread: Identifiable, Codable, Sendable {
    let id: String
    let subject: String
    var messages: [MailMessage]
    var lastMessageDate: Date

    // Intelligence metadata
    var intent: String?
    var extractedEntities: [String: String]?
    var priorityScore: Double?
    var sentiment: String?

    var isRead: Bool {
        messages.allSatisfy { $0.isRead }
    }

    var snippet: String {
        messages.last?.body.prefix(100).description ?? ""
    }

    var participants: [String] {
        Array(Set(messages.flatMap { [$0.from] + $0.to })).sorted()
    }
}
