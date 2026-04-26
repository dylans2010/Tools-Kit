import Foundation

struct AgentDebugSnapshot: Codable {
    let id: UUID
    let timestamp: Date
    let state: SystemAgentState
    let history: [SystemAgentMessage]

    init(state: SystemAgentState, history: [SystemAgentMessage]) {
        self.id = UUID()
        self.timestamp = Date()
        self.state = state
        self.history = history
    }
}
