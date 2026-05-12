// ToolsKit — SDKHealthMonitor.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for health monitoring.
@MainActor
public protocol SDKHealthMonitorProtocol: AnyObject {
    var overallStatus: SDKHealthStatus { get }
    var componentStatuses: [SDKComponentHealth] { get }
    func checkHealth() async -> SDKHealthReport
    func registerProbe(name: String, probe: @escaping () async -> SDKHealthStatus)
}

/// Health status for a component or the overall system.
public enum SDKHealthStatus: String, Codable, Sendable, CaseIterable {
    case healthy
    case degraded
    case unhealthy
    case unknown

    public var isOperational: Bool {
        self == .healthy || self == .degraded
    }
}

/// Health information for a single component.
public struct SDKComponentHealth: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: SDKHealthStatus
    public let message: String
    public let checkedAt: Date
    public let latency: TimeInterval

    public init(name: String, status: SDKHealthStatus, message: String = "", latency: TimeInterval = 0) {
        self.id = name
        self.name = name
        self.status = status
        self.message = message
        self.checkedAt = Date()
        self.latency = latency
    }
}

/// Comprehensive health report for the SDK.
public struct SDKHealthReport: Sendable {
    public let overallStatus: SDKHealthStatus
    public let components: [SDKComponentHealth]
    public let timestamp: Date
    public let checkDuration: TimeInterval

    public init(overallStatus: SDKHealthStatus, components: [SDKComponentHealth], checkDuration: TimeInterval) {
        self.overallStatus = overallStatus
        self.components = components
        self.timestamp = Date()
        self.checkDuration = checkDuration
    }
}

/// Continuous health monitoring system for all SDK components.
@MainActor
public final class SDKHealthMonitor: SDKHealthMonitorProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKHealthMonitor()

    @Published public private(set) var overallStatus: SDKHealthStatus = .unknown
    @Published public private(set) var componentStatuses: [SDKComponentHealth] = []
    @Published public private(set) var lastReport: SDKHealthReport?
    @Published public private(set) var checkCount: Int = 0

    private var probes: [String: () async -> SDKHealthStatus] = [:]
    private var monitoringTask: Task<Void, Never>?
    private let checkInterval: TimeInterval

    private init(checkInterval: TimeInterval = 60.0) {
        self.checkInterval = checkInterval
        registerDefaultProbes()
    }

    public func registerProbe(name: String, probe: @escaping () async -> SDKHealthStatus) {
        probes[name] = probe
    }

    public func removeProbe(name: String) {
        probes.removeValue(forKey: name)
    }

    public func checkHealth() async -> SDKHealthReport {
        let startTime = Date()
        var components: [SDKComponentHealth] = []

        for (name, probe) in probes.sorted(by: { $0.key < $1.key }) {
            let probeStart = Date()
            let status = await probe()
            let latency = Date().timeIntervalSince(probeStart)
            let component = SDKComponentHealth(
                name: name,
                status: status,
                latency: latency
            )
            components.append(component)
        }

        let overall = computeOverallStatus(from: components)
        let duration = Date().timeIntervalSince(startTime)
        let report = SDKHealthReport(
            overallStatus: overall,
            components: components,
            checkDuration: duration
        )

        overallStatus = overall
        componentStatuses = components
        lastReport = report
        checkCount += 1

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.health",
            name: "health.checked",
            data: ["status": overall.rawValue, "components": "\(components.count)"]
        ))

        return report
    }

    public func startMonitoring() {
        stopMonitoring()
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                _ = await self.checkHealth()
                try? await Task.sleep(nanoseconds: UInt64(self.checkInterval * 1_000_000_000))
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

    private func computeOverallStatus(from components: [SDKComponentHealth]) -> SDKHealthStatus {
        if components.isEmpty { return .unknown }
        if components.allSatisfy({ $0.status == .healthy }) { return .healthy }
        if components.contains(where: { $0.status == .unhealthy }) { return .unhealthy }
        if components.contains(where: { $0.status == .degraded }) { return .degraded }
        return .unknown
    }

    private func registerDefaultProbes() {
        registerProbe(name: "Kernel") { @MainActor in
            switch WorkspaceSDKKernel.shared.state {
            case .ready: return .healthy
            case .booting: return .degraded
            case .error: return .unhealthy
            case .idle, .shuttingDown: return .degraded
            }
        }

        registerProbe(name: "DataStore") { @MainActor in
            SDKDataStore.shared.isInitialized ? .healthy : .unhealthy
        }

        registerProbe(name: "EventBus") { @MainActor in
            SDKEventBus.shared.isRunning ? .healthy : .degraded
        }

        registerProbe(name: "Cache") { @MainActor in
            SDKCacheManager.shared.entryCount >= 0 ? .healthy : .unknown
        }
    }
}
