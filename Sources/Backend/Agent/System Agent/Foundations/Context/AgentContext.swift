import Foundation

public struct AgentContext: Codable {
    public var messages: [SystemAgentMessage]
    public var metadata: [String: String]

    public init(messages: [SystemAgentMessage] = [], metadata: [String: String] = [:]) {
        self.messages = messages
        self.metadata = metadata
    }
}
