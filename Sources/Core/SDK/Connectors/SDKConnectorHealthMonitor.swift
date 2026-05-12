// ToolsKit — SDKConnectorHealthMonitor.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Protocol for connector health monitoring.
@MainActor
public protocol SDKConnectorHealthMonitorProtocol: AnyObject {
    func checkConnector(id: UUID) async -> SDKConnectorHealthStatus
    func checkAll() async -> [SDKConnectorHealthStatus]
    var healthStatuses: [SDKConnectorHealthStatus] { get }
}

/// Health status for a single connector.
public struct SDKConnectorHealthStatus: Identifiable, Sendable {
    public let id: UUID
    public let connectorName: String
    public let status: SDKHealthStatus
    public let lastChecked: Date
    public let latency: TimeInterval
    public let errorMessage: String?
    public let consecutiveFailures: Int

    public init(
        id: UUID,
        connectorName: String,
        status: SDKHealthStatus,
        latency: TimeInterval = 0,
        errorMessage: String? = nil,
        consecutiveFailures: Int = 0
    ) {
        self.id = id
        self.connectorName = connectorName
        self.status = status
        self.lastChecked = Date()
        self.latency = latency
        self.errorMessage = errorMessage
        self.consecutiveFailures = consecutiveFailures
    }
}

/// Monitors health of all registered connectors.
@MainActor
public final class SDKConnectorHealthMonitor: SDKConnectorHealthMonitorProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKConnectorHealthMonitor()

    @Published public private(set) var healthStatuses: [SDKConnectorHealthStatus] = []
    @Published public private(set) var lastFullCheck: Date?
    @Published public private(set) var overallHealth: SDKHealthStatus = .unknown

    private var failureCounts: [UUID: Int] = [:]
    private var monitoringTask: Task<Void, Never>?

    private init() {}

    public func checkConnector(id: UUID) async -> SDKConnectorHealthStatus {
        let connectors = SDKConnectorManager.shared.connectors
        guard let connector = connectors.first(where: { $0.id == id }) else {
            return SDKConnectorHealthStatus(
                id: id,
                connectorName: "Unknown",
                status: .unknown,
                errorMessage: "Connector not found"
            )
        }

        let startTime = Date()
        do {
            let isConnected = try await connector.testConnection()
            let latency = Date().timeIntervalSince(startTime)

            if isConnected {
                failureCounts[id] = 0
                let status = SDKConnectorHealthStatus(
                    id: id,
                    connectorName: connector.name,
                    status: .healthy,
                    latency: latency
                )
                updateStatus(status)
                return status
            } else {
                let failures = incrementFailure(id: id)
                let healthStatus: SDKHealthStatus = failures >= 3 ? .unhealthy : .degraded
                let status = SDKConnectorHealthStatus(
                    id: id,
                    connectorName: connector.name,
                    status: healthStatus,
                    latency: latency,
                    errorMessage: "Connection test returned false",
                    consecutiveFailures: failures
                )
                updateStatus(status)
                return status
            }
        } catch {
            let latency = Date().timeIntervalSince(startTime)
            let failures = incrementFailure(id: id)
            let healthStatus: SDKHealthStatus = failures >= 3 ? .unhealthy : .degraded
            let status = SDKConnectorHealthStatus(
                id: id,
                connectorName: connector.name,
                status: healthStatus,
                latency: latency,
                errorMessage: error.localizedDescription,
                consecutiveFailures: failures
            )
            updateStatus(status)
            return status
        }
    }

    public func checkAll() async -> [SDKConnectorHealthStatus] {
        let connectors = SDKConnectorManager.shared.connectors
        var results: [SDKConnectorHealthStatus] = []

        for connector in connectors {
            let status = await checkConnector(id: connector.id)
            results.append(status)
        }

        lastFullCheck = Date()
        updateOverallHealth()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.connectors",
            name: "health.checked",
            data: ["count": "\(results.count)", "overall": overallHealth.rawValue]
        ))

        return results
    }

    public func startMonitoring(interval: TimeInterval = 120) {
        stopMonitoring()
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                _ = await self.checkAll()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    public var isMonitoring: Bool {
        monitoringTask != nil && !(monitoringTask?.isCancelled ?? true)
    }

    private func incrementFailure(id: UUID) -> Int {
        let count = (failureCounts[id] ?? 0) + 1
        failureCounts[id] = count
        return count
    }

    private func updateStatus(_ status: SDKConnectorHealthStatus) {
        if let index = healthStatuses.firstIndex(where: { $0.id == status.id }) {
            healthStatuses[index] = status
        } else {
            healthStatuses.append(status)
        }
        updateOverallHealth()
    }

    private func updateOverallHealth() {
        if healthStatuses.isEmpty {
            overallHealth = .unknown
        } else if healthStatuses.allSatisfy({ $0.status == .healthy }) {
            overallHealth = .healthy
        } else if healthStatuses.contains(where: { $0.status == .unhealthy }) {
            overallHealth = .unhealthy
        } else if healthStatuses.contains(where: { $0.status == .degraded }) {
            overallHealth = .degraded
        } else {
            overallHealth = .unknown
        }
    }
}
