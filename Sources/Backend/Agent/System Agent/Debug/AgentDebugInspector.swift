import Foundation

final class AgentDebugInspector {
    init() {}

    func inspect(snapshot: AgentDebugSnapshot) -> String {
        "Snapshot \(snapshot.id) at \(snapshot.timestamp): State \(snapshot.state), \(snapshot.history.count) messages"
    }
}
