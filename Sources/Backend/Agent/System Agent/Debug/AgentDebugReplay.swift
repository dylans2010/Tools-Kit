import Foundation

public final class AgentDebugReplay {
    public init() {}

    public func replay(snapshot: AgentDebugSnapshot, onMessage: (SystemAgentMessage) -> Void) {
        snapshot.history.forEach(onMessage)
    }
}
