import Foundation

struct AgentToolRetryHandler: Sendable {
    let maxRetries: Int

    init(maxRetries: Int = 3) {
        self.maxRetries = maxRetries
    }

    func shouldRetry(error: Error, attempt: Int) -> Bool {
        attempt < maxRetries
    }
}
