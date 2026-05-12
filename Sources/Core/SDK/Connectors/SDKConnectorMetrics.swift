// ToolsKit — SDKConnectorMetrics.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Protocol for connector metrics tracking.
@MainActor
public protocol SDKConnectorMetricsProtocol: AnyObject {
    func recordRequest(connectorID: UUID, duration: TimeInterval, success: Bool)
    func metrics(for connectorID: UUID) -> SDKConnectorMetricsSummary?
    var allMetrics: [SDKConnectorMetricsSummary] { get }
}

/// Metrics summary for a single connector.
public struct SDKConnectorMetricsSummary: Identifiable, Sendable {
    public let id: UUID
    public let connectorName: String
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageLatency: TimeInterval
    public let p95Latency: TimeInterval
    public let minLatency: TimeInterval
    public let maxLatency: TimeInterval
    public let lastRequestAt: Date?
    public let uptime: TimeInterval

    public var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulRequests) / Double(totalRequests)
    }

    public init(
        id: UUID,
        connectorName: String,
        totalRequests: Int,
        successfulRequests: Int,
        failedRequests: Int,
        averageLatency: TimeInterval,
        p95Latency: TimeInterval,
        minLatency: TimeInterval,
        maxLatency: TimeInterval,
        lastRequestAt: Date?,
        uptime: TimeInterval
    ) {
        self.id = id
        self.connectorName = connectorName
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageLatency = averageLatency
        self.p95Latency = p95Latency
        self.minLatency = minLatency
        self.maxLatency = maxLatency
        self.lastRequestAt = lastRequestAt
        self.uptime = uptime
    }
}

/// Tracks performance metrics for all connectors.
@MainActor
public final class SDKConnectorMetricsTracker: SDKConnectorMetricsProtocol, ObservableObject {
    public static let shared = SDKConnectorMetricsTracker()

    @Published public private(set) var allMetrics: [SDKConnectorMetricsSummary] = []
    @Published public private(set) var totalRequests: Int = 0

    private var connectorData: [UUID: ConnectorMetricsData] = [:]

    private struct ConnectorMetricsData: Sendable {
        var connectorName: String
        var latencies: [TimeInterval] = []
        var successCount: Int = 0
        var failureCount: Int = 0
        var lastRequestAt: Date?
        var startedAt: Date = Date()
    }

    private init() {}

    public func recordRequest(connectorID: UUID, duration: TimeInterval, success: Bool) {
        if connectorData[connectorID] == nil {
            let name = SDKConnectorManager.shared.connectors
                .first(where: { $0.id == connectorID })?.name ?? "Unknown"
            connectorData[connectorID] = ConnectorMetricsData(connectorName: name)
        }

        connectorData[connectorID]?.latencies.append(duration)
        if success {
            connectorData[connectorID]?.successCount += 1
        } else {
            connectorData[connectorID]?.failureCount += 1
        }
        connectorData[connectorID]?.lastRequestAt = Date()

        if let data = connectorData[connectorID], data.latencies.count > 1000 {
            connectorData[connectorID]?.latencies = Array(data.latencies.suffix(500))
        }

        totalRequests += 1
        rebuildSummaries()

        SDKMetricsCollector.shared.timing("connector.\(connectorID.uuidString).latency", duration: duration)
        SDKMetricsCollector.shared.increment("connector.requests.total")
    }

    public func metrics(for connectorID: UUID) -> SDKConnectorMetricsSummary? {
        allMetrics.first(where: { $0.id == connectorID })
    }

    public func reset(connectorID: UUID) {
        connectorData.removeValue(forKey: connectorID)
        rebuildSummaries()
    }

    public func resetAll() {
        connectorData.removeAll()
        allMetrics.removeAll()
        totalRequests = 0
    }

    private func rebuildSummaries() {
        allMetrics = connectorData.map { id, data in
            let sorted = data.latencies.sorted()
            let avg = sorted.isEmpty ? 0 : sorted.reduce(0, +) / Double(sorted.count)
            let p95Index = sorted.isEmpty ? 0 : Int(Double(sorted.count) * 0.95)
            let p95 = sorted.isEmpty ? 0 : sorted[min(p95Index, sorted.count - 1)]
            let minVal = sorted.first ?? 0
            let maxVal = sorted.last ?? 0
            let uptime = Date().timeIntervalSince(data.startedAt)

            return SDKConnectorMetricsSummary(
                id: id,
                connectorName: data.connectorName,
                totalRequests: data.successCount + data.failureCount,
                successfulRequests: data.successCount,
                failedRequests: data.failureCount,
                averageLatency: avg,
                p95Latency: p95,
                minLatency: minVal,
                maxLatency: maxVal,
                lastRequestAt: data.lastRequestAt,
                uptime: uptime
            )
        }
        .sorted { $0.connectorName < $1.connectorName }
    }
}
