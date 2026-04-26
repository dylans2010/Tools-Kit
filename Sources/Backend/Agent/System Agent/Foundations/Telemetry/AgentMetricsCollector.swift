import Foundation

final class AgentMetricsCollector {
    static let shared = AgentMetricsCollector()
    private var metrics: [String: Int] = [:]
    private let queue = DispatchQueue(label: "com.tools-kit.agent.metrics")

    private init() {}

    func increment(metric: String) {
        queue.async {
            self.metrics[metric, default: 0] += 1
        }
    }

    func getMetrics() -> [String: Int] {
        queue.sync { metrics }
    }
}
