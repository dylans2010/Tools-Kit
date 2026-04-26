import Foundation

public final class AgentDebugSession {
    public let id: UUID
    private var snapshots: [AgentDebugSnapshot] = []

    public init() {
        self.id = UUID()
    }

    public func capture(state: SystemAgentState, history: [SystemAgentMessage]) {
        snapshots.append(AgentDebugSnapshot(state: state, history: history))
    }

    public func getSnapshots() -> [AgentDebugSnapshot] {
        snapshots
    }
}
