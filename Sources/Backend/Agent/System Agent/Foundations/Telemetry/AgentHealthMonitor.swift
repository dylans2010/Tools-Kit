import Foundation

actor AgentHealthMonitor {
    enum HealthStatus: Codable { case healthy, degraded(reason: String), critical(reason: String) }

    private var continuation: AsyncStream<HealthStatus>.Continuation?
    private var monitorTask: Task<Void, Never>?
    private var lastStatus: HealthStatus = .healthy

    var healthStream: AsyncStream<HealthStatus> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.lastStatus)
        }
    }

    func currentStatus() async -> HealthStatus { lastStatus }

    func startMonitoring(interval: TimeInterval) {
        monitorTask?.cancel()
        monitorTask = Task {
            while !Task.isCancelled {
                continuation?.yield(lastStatus)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopMonitoring() { monitorTask?.cancel(); monitorTask = nil }
}
