import Foundation

struct AgentToolRetryHandler {
    func retry<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
        precondition(maxAttempts > 0)
        var lastError: Error?
        for _ in 0..<maxAttempts {
            do { return try await operation() }
            catch { lastError = error }
        }
        throw lastError ?? NSError(domain: "AgentToolRetryHandler", code: 1)
    }
}
