import Foundation

final class SystemAgentSession: Codable, Identifiable {
    let id: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [SystemAgentMessage]
    var metadata: [String: String]

    init(id: String = UUID().uuidString) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
        self.metadata = [:]
    }

    func addMessage(_ message: SystemAgentMessage) {
        messages.append(message)
        updatedAt = Date()
    }
}
