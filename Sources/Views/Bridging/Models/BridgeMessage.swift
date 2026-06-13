import Foundation

public struct BridgeMessage: Codable, Identifiable, Equatable {
    public let id: UUID
    public var content: String
    public let timestamp: Date
    public let sender: Sender
    public let agentSource: AgentSource?

    public enum Sender: String, Codable {
        case user
        case host
    }

    public enum AgentSource: String, Codable {
        case codex = "Codex"
        case claude = "Claude Code"
        case local = "Local Model"
    }

    public init(id: UUID = UUID(), content: String, timestamp: Date = Date(), sender: Sender, agentSource: AgentSource? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sender = sender
        self.agentSource = agentSource
    }
}
