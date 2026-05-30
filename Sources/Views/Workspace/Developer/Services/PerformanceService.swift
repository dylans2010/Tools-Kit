import Foundation

public class PerformanceService: ObservableObject {
    public static let shared = PerformanceService()
    private let store = DeveloperPersistentStore.shared

    @Published public var metrics: [PerformanceMetric] = []

    private init() { loadMetrics() }

    public func loadMetrics() { self.metrics = store.performanceMetrics }

    public func recordMetric(_ metric: PerformanceMetric) async throws {
        var current = store.performanceMetrics
        current.insert(metric, at: 0)
        if current.count > 1000 { current.removeLast() }
        store.savePerformanceMetrics(current)
        await MainActor.run { self.metrics = current }
    }
}
