import Foundation

public final class AgentDebugBenchmark {
    public init() {}

    public func runBenchmark(task: () async -> Void) async -> TimeInterval {
        let start = Date()
        await task()
        return Date().timeIntervalSince(start)
    }
}
