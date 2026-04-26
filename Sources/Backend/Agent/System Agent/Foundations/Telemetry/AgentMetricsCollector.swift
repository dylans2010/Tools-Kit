import Foundation

struct AgentMetricsCollector {
    func countTokens(in text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }
}
