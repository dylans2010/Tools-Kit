// ToolsKit — AnalyticsPlugin.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Analytics plugin that tracks SDK usage patterns and provides insights.
@MainActor
public final class AnalyticsPlugin: SDKPluginConformable, ObservableObject {
    public let id: UUID
    public let pluginIdentifier = "com.toolskit.plugin.analytics"
    public let pluginDisplayName = "Analytics"
    public let pluginVersion = "1.0.0"
    public let pluginDescription = "Tracks SDK usage patterns and provides analytics insights"
    public let pluginCategory: SDKPluginCategory = .analytics
    public let requiredCapabilities: [SDKPluginCapability] = [SDKPluginCapability(name: "analytics"), SDKPluginCapability(name: "eventPublishing")]
    public let requiredScopes: [String] = ["workspace.analytics.read"]

    @Published public private(set) var eventCount: Int = 0
    @Published public private(set) var sessionStartedAt: Date?
    @Published public private(set) var topEvents: [EventSummary] = []
    @Published public private(set) var isActive: Bool = false

    private var eventCounts: [String: Int] = [:]
    private var cancellable: AnyCancellable?

    public struct EventSummary: Identifiable, Sendable {
        public let id: String
        public let eventName: String
        public let count: Int
        public let lastOccurred: Date

        public init(eventName: String, count: Int) {
            self.id = eventName
            self.eventName = eventName
            self.count = count
            self.lastOccurred = Date()
        }
    }

    public init(id: UUID = UUID()) {
        self.id = id
    }

    public func onActivate() async throws {
        isActive = true
        sessionStartedAt = Date()
        startTracking()

        SDKMetricsCollector.shared.increment("analytics.activations")
    }

    public func onDeactivate() async throws {
        isActive = false
        stopTracking()

        SDKMetricsCollector.shared.gauge("analytics.totalEvents", value: Double(eventCount))
    }

    public func onPause() async throws {
        stopTracking()
    }

    public func onResume() async throws {
        startTracking()
    }

    public func healthCheck() async -> SDKHealthStatus {
        isActive ? .healthy : .degraded
    }

    public func summary() -> [EventSummary] {
        eventCounts.map { EventSummary(eventName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    public func eventCount(for eventName: String) -> Int {
        eventCounts[eventName] ?? 0
    }

    public func reset() {
        eventCount = 0
        eventCounts.removeAll()
        topEvents.removeAll()
    }

    public var sessionDuration: TimeInterval {
        guard let start = sessionStartedAt else { return 0 }
        return Date().timeIntervalSince(start)
    }

    private func startTracking() {
        cancellable = SDKEventBus.shared.subscribeAll { [weak self] event in
            Task { @MainActor [weak self] in
                self?.trackEvent(event)
            }
        }
    }

    private func stopTracking() {
        cancellable?.cancel()
        cancellable = nil
    }

    private func trackEvent(_ event: SDKBusEvent) {
        let key = "\(event.channel).\(event.name)"
        eventCounts[key, default: 0] += 1
        eventCount += 1

        topEvents = summary().prefix(10).map { $0 }

        if eventCount % 100 == 0 {
            SDKMetricsCollector.shared.gauge("analytics.eventsPerSession", value: Double(eventCount))
        }
    }
}
