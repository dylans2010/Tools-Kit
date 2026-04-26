import Foundation

final class AgentDebugReplay {
    init() {}

    func replay(snapshot: AgentDebugSnapshot, onMessage: (SystemAgentMessage) -> Void) {
        snapshot.history.forEach(onMessage)
    }
}
