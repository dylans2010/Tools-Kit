import Foundation

struct AgentDebugBenchmark {
    func measure(_ block: () -> Void) -> TimeInterval {
        let start = Date()
        block()
        return Date().timeIntervalSince(start)
    }
}
