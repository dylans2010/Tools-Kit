import Foundation

struct AgentContextCompressor {
    func compress(messages: [SystemAgentMessage], targetTokenCount: Int) -> [SystemAgentMessage] {
        let before = estimate(messages)
        guard before > targetTokenCount, messages.count > 10 else { return messages }
        let tail = Array(messages.suffix(10))
        let protected = messages.dropLast(10).filter {
            if case .toolCall = $0.role { return true }
            if case .toolResult = $0.role { return true }
            return false
        }
        let summaryText = "[CONTEXT SUMMARY] Compressed \(messages.count - tail.count - protected.count) prior conversational messages."
        let summary = SystemAgentMessage(role: .assistant, content: summaryText)
        let output = [summary] + Array(protected) + tail
        Task { await AgentAPILogger.shared.log(level: .info, component: "AgentContextCompressor", message: "Compressed context \(before)->\(estimate(output)) tokens") }
        return output
    }

    private func estimate(_ messages: [SystemAgentMessage]) -> Int { messages.map { max($0.content.count / 4, 1) }.reduce(0,+) }
}
