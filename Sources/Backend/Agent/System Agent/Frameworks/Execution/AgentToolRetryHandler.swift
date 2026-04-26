import Foundation

public struct AgentToolRetryHandler {
    public let maxRetries: Int

    public init(maxRetries: Int = 3) {
        self.maxRetries = maxRetries
    }

    public func shouldRetry(error: Error, attempt: Int) -> Bool {
        attempt < maxRetries
    }
}
