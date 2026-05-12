import Foundation

struct AgentAPIRequest: Codable, Identifiable, Sendable {
    let id: UUID
    let model: String
    let messages: [AgentAPIMessage]

    init(id: UUID = UUID(), model: String, messages: [AgentAPIMessage]) {
        self.id = id
        self.model = model
        self.messages = messages
    }
}
