import Foundation

final class AgentDebugSession {
    let id: UUID
    private var snapshots: [AgentDebugSnapshot] = []

    init() {
        self.id = UUID()
    }

    func capture(state: SystemAgentState, history: [SystemAgentMessage]) {
        snapshots.append(AgentDebugSnapshot(state: state, history: history))
    }

    func getSnapshots() -> [AgentDebugSnapshot] {
        snapshots
    }
}
