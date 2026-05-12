import Foundation

struct AgentContext: Codable, Sendable {
    var messages: [SystemAgentMessage]
    var metadata: [String: String]

    init(messages: [SystemAgentMessage] = [], metadata: [String: String] = [:]) {
        self.messages = messages
        self.metadata = metadata
    }
}
