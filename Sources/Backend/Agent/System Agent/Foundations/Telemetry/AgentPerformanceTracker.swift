import Foundation

final class AgentPerformanceTracker {
    private var startTimes: [String: Date] = [:]
    private let queue = DispatchQueue(label: "com.tools-kit.agent.performance")

    init() {}

    func start(task: String) {
        queue.async {
            self.startTimes[task] = Date()
        }
    }

    func stop(task: String) -> TimeInterval? {
        queue.sync {
            guard let start = self.startTimes.removeValue(forKey: task) else { return nil }
            return Date().timeIntervalSince(start)
        }
    }
}
