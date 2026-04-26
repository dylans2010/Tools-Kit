import Foundation

struct AgentContext: Codable {
    var messages: [SystemAgentMessage]
    var metadata: [String: String]

    init(messages: [SystemAgentMessage] = [], metadata: [String: String] = [:]) {
        self.messages = messages
        self.metadata = metadata
    }
}
