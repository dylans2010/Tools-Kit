import Foundation

final class AgentDebugBenchmark {
    init() {}

    func runBenchmark(task: () async -> Void) async -> TimeInterval {
        let start = Date()
        await task()
        return Date().timeIntervalSince(start)
    }
}
