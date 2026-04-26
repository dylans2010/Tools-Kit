import Foundation

struct SystemAgentSession: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var messages: [SystemAgentMessage]

    init(id: UUID = UUID(), createdAt: Date = Date(), messages: [SystemAgentMessage] = []) {
        self.id = id
        self.createdAt = createdAt
        self.messages = messages
    }
}
