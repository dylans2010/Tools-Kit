import Foundation

public final class AgentDebugInspector {
    public init() {}

    public func inspect(snapshot: AgentDebugSnapshot) -> String {
        "Snapshot \(snapshot.id) at \(snapshot.timestamp): State \(snapshot.state), \(snapshot.history.count) messages"
    }
}
