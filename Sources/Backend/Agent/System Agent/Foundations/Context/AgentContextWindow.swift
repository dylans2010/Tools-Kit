import Foundation

public struct AgentContextWindow {
    public let maxTokens: Int
    public private(set) var currentTokens: Int = 0

    public init(maxTokens: Int) {
        self.maxTokens = maxTokens
    }

    public mutating func update(current: Int) {
        self.currentTokens = current
    }

    public var remainingTokens: Int {
        max(0, maxTokens - currentTokens)
    }

    public var isExceeded: Bool {
        currentTokens > maxTokens
    }
}
