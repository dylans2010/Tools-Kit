import Foundation

enum AgentStreamEvent: Sendable {
    case token(String)
    case toolCallStart(String)
    case toolCallEnd(String, String)
    case complete(String)
}

struct AgentStreamEventParser: Sendable {
    init() {}

    func parse(chunk: String) -> [AgentStreamEvent] {
        // Basic parser that looks for tool call markers or just treats as tokens
        if chunk.contains("\"tool\":") {
            // Simplified detection for this implementation
            return [.toolCallStart(chunk)]
        } else if chunk.hasPrefix("data: [DONE]") {
            return [.complete(chunk)]
        }
        return [.token(chunk)]
    }
}
