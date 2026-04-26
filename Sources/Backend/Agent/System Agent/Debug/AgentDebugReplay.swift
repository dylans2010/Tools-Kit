import Foundation

struct AgentDebugReplay {
    func replay(_ messages: [SystemAgentMessage], handler: (SystemAgentMessage) -> Void) {
        messages.forEach(handler)
    }
}
