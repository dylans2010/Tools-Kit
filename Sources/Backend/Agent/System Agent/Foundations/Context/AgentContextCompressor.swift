import Foundation

public struct AgentContextCompressor {
    public init() {}

    public func compress(_ context: AgentContext, targetTokenCount: Int) -> AgentContext {
        // Basic compression strategy: keep recent messages, remove oldest non-system messages.
        var messages = context.messages

        // We simulate token count by message length for this implementation
        var currentApproxTokens = messages.reduce(0) { $0 + $1.content.count / 4 }

        while currentApproxTokens > targetTokenCount && messages.count > 1 {
            // Keep the system prompt (assume first message if role matches)
            if messages[0].role == .user || messages[0].role == .assistant {
                let removed = messages.removeFirst()
                currentApproxTokens -= removed.content.count / 4
            } else if messages.count > 1 {
                let removed = messages.remove(at: 1)
                currentApproxTokens -= removed.content.count / 4
            } else {
                break
            }
        }

        return AgentContext(messages: messages, metadata: context.metadata)
    }
}
