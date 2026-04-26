import Foundation

public final class AgentMetricsCollector {
    public static let shared = AgentMetricsCollector()
    private var metrics: [String: Int] = [:]
    private let queue = DispatchQueue(label: "com.tools-kit.agent.metrics")

    private init() {}

    public func increment(metric: String) {
        queue.async {
            self.metrics[metric, default: 0] += 1
        }
    }

    public func getMetrics() -> [String: Int] {
        queue.sync { metrics }
    }
}
