import Foundation

public struct AgentDebugSnapshot: Codable {
    public let id: UUID
    public let timestamp: Date
    public let state: SystemAgentState
    public let history: [SystemAgentMessage]

    public init(state: SystemAgentState, history: [SystemAgentMessage]) {
        self.id = UUID()
        self.timestamp = Date()
        self.state = state
        self.history = history
    }
}
