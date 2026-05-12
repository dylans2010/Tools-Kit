// ToolsKit — SDKMetricsCollector.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for metrics collection.
@MainActor
public protocol SDKMetricsCollectorProtocol: AnyObject {
    func increment(_ metric: String, by value: Int)
    func gauge(_ metric: String, value: Double)
    func timing(_ metric: String, duration: TimeInterval)
    func snapshot() -> SDKMetricsSnapshot
}

/// A single metric data point.
public struct SDKMetricPoint: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let value: Double
    public let timestamp: Date
    public let kind: MetricKind

    public enum MetricKind: String, Sendable {
        case counter, gauge, timing
    }

    public init(name: String, value: Double, kind: MetricKind) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.timestamp = Date()
        self.kind = kind
    }
}

/// Snapshot of all current metrics.
public struct SDKMetricsSnapshot: Sendable {
    public let counters: [String: Int]
    public let gauges: [String: Double]
    public let timings: [String: [TimeInterval]]
    public let timestamp: Date

    public init(counters: [String: Int], gauges: [String: Double], timings: [String: [TimeInterval]]) {
        self.counters = counters
        self.gauges = gauges
        self.timings = timings
        self.timestamp = Date()
    }

    public func averageTiming(for metric: String) -> TimeInterval? {
        guard let values = timings[metric], !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    public func p95Timing(for metric: String) -> TimeInterval? {
        guard let values = timings[metric], !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
}

/// Collects and aggregates SDK performance metrics.
@MainActor
public final class SDKMetricsCollector: SDKMetricsCollectorProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKMetricsCollector()

    @Published public private(set) var recentPoints: [SDKMetricPoint] = []
    @Published public private(set) var totalPointsRecorded: Int = 0

    private var counters: [String: Int] = [:]
    private var gauges: [String: Double] = [:]
    private var timings: [String: [TimeInterval]] = [:]
    private let maxTimingHistory = 100
    private let maxRecentPoints = 200

    private init() {}

    public func increment(_ metric: String, by value: Int = 1) {
        counters[metric, default: 0] += value
        recordPoint(SDKMetricPoint(name: metric, value: Double(counters[metric] ?? 0), kind: .counter))
    }

    public func gauge(_ metric: String, value: Double) {
        gauges[metric] = value
        recordPoint(SDKMetricPoint(name: metric, value: value, kind: .gauge))
    }

    public func timing(_ metric: String, duration: TimeInterval) {
        var history = timings[metric] ?? []
        history.append(duration)
        if history.count > maxTimingHistory {
            history = Array(history.suffix(maxTimingHistory))
        }
        timings[metric] = history
        recordPoint(SDKMetricPoint(name: metric, value: duration, kind: .timing))
    }

    public func measureAsync<T>(_ metric: String, operation: () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(start)
        timing(metric, duration: duration)
        return result
    }

    public func snapshot() -> SDKMetricsSnapshot {
        SDKMetricsSnapshot(counters: counters, gauges: gauges, timings: timings)
    }

    public func counter(_ metric: String) -> Int {
        counters[metric] ?? 0
    }

    public func currentGauge(_ metric: String) -> Double? {
        gauges[metric]
    }

    public func reset() {
        counters.removeAll()
        gauges.removeAll()
        timings.removeAll()
        recentPoints.removeAll()
        totalPointsRecorded = 0
    }

    public func reset(metric: String) {
        counters.removeValue(forKey: metric)
        gauges.removeValue(forKey: metric)
        timings.removeValue(forKey: metric)
    }

    public func allMetricNames() -> [String] {
        let allNames = Set(counters.keys).union(gauges.keys).union(timings.keys)
        return Array(allNames).sorted()
    }

    private func recordPoint(_ point: SDKMetricPoint) {
        recentPoints.insert(point, at: 0)
        if recentPoints.count > maxRecentPoints {
            recentPoints = Array(recentPoints.prefix(maxRecentPoints))
        }
        totalPointsRecorded += 1
    }
}
