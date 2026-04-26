import Foundation

public final class AgentPerformanceTracker {
    private var startTimes: [String: Date] = [:]
    private let queue = DispatchQueue(label: "com.tools-kit.agent.performance")

    public init() {}

    public func start(task: String) {
        queue.async {
            self.startTimes[task] = Date()
        }
    }

    public func stop(task: String) -> TimeInterval? {
        queue.sync {
            guard let start = self.startTimes.removeValue(forKey: task) else { return nil }
            return Date().timeIntervalSince(start)
        }
    }
}
