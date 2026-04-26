import Foundation

struct AgentDebugInspector {
    func summarize(messages: [SystemAgentMessage]) -> String {
        let counts = Dictionary(grouping: messages) { message in
            switch message.role {
            case .system: return "system"
            case .user: return "user"
            case .assistant: return "assistant"
            case .toolCall: return "toolCall"
            case .toolResult: return "toolResult"
            case .failed: return "failed"
            }
        }.mapValues(\.count)

        return counts.keys.sorted().map { "\($0): \(counts[$0] ?? 0)" }.joined(separator: ", ")
    }
}
