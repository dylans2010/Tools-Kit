import Foundation

struct AgentContextWindow: Sendable {
    let maxTokens: Int
    private(set) var currentTokens: Int = 0

    init(maxTokens: Int) {
        self.maxTokens = maxTokens
    }

    mutating func update(current: Int) {
        self.currentTokens = current
    }

    var remainingTokens: Int {
        max(0, maxTokens - currentTokens)
    }

    var isExceeded: Bool {
        currentTokens > maxTokens
    }
}
