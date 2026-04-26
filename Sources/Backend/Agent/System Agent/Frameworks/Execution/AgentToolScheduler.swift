import Foundation

struct AgentToolScheduler {
    func runSequentially(_ tasks: [() async throws -> Void]) async throws {
        for task in tasks {
            try Task.checkCancellation()
            try await task()
        }
    }
}
