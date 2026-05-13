import Foundation
import Combine

@MainActor
public final class SDKAnalyticsEngine: ObservableObject {
    public static let shared = SDKAnalyticsEngine()

    @Published public private(set) var events: [AnalyticsEvent] = []
    @Published public private(set) var sessionMetrics: SessionMetrics = .empty
    @Published public private(set) var isTracking = false

    private var cancellables = Set<AnyCancellable>()
    private let maxBufferSize = 1000

    private init() {
        observeEventBus()
    }

    // MARK: - Event Tracking

    public func track(_ name: String, category: AnalyticsCategory, properties: [String: String] = [:]) {
        guard isTracking else { return }
        let event = AnalyticsEvent(
            name: name,
            category: category,
            properties: properties,
            timestamp: Date()
        )
        events.append(event)
        if events.count > maxBufferSize {
            events.removeFirst(events.count - maxBufferSize)
        }
        sessionMetrics = sessionMetrics.incrementing(category: category)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.analytics",
            name: "event.tracked",
            data: ["event": name, "category": category.rawValue]
        ))
    }

    public func trackScreenView(_ screenName: String) {
        track("screen_view", category: .navigation, properties: ["screen": screenName])
    }

    public func trackAction(_ action: String, target: String = "") {
        track("user_action", category: .interaction, properties: ["action": action, "target": target])
    }

    public func trackError(_ error: String, context: String = "") {
        track("error", category: .error, properties: ["error": error, "context": context])
    }

    public func trackPerformance(_ operation: String, duration: TimeInterval) {
        track("performance", category: .performance, properties: [
            "operation": operation,
            "duration_ms": String(format: "%.1f", duration * 1000)
        ])
    }

    // MARK: - Session Control

    public func startTracking() {
        isTracking = true
        sessionMetrics = SessionMetrics(startedAt: Date())
    }

    public func stopTracking() {
        isTracking = false
    }

    public func flush() -> [AnalyticsEvent] {
        let flushed = events
        events.removeAll()
        return flushed
    }

    // MARK: - Queries

    public func events(for category: AnalyticsCategory) -> [AnalyticsEvent] {
        events.filter { $0.category == category }
    }

    public func eventCount(for category: AnalyticsCategory) -> Int {
        events.count(where: { $0.category == category })
    }

    public func recentEvents(limit: Int = 50) -> [AnalyticsEvent] {
        Array(events.suffix(limit))
    }

    // MARK: - Private

    private func observeEventBus() {
        SDKEventBus.shared.subscribe(channel: "sdk.*") { [weak self] event in
            Task { @MainActor in
                self?.track("bus_event", category: .system, properties: [
                    "channel": event.channel,
                    "name": event.name
                ])
            }
        }
        .store(in: &cancellables)
    }
}

// MARK: - Models

public struct AnalyticsEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let category: AnalyticsCategory
    public let properties: [String: String]
    public let timestamp: Date

    public init(name: String, category: AnalyticsCategory, properties: [String: String] = [:], timestamp: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = timestamp
    }
}

public enum AnalyticsCategory: String, Codable, CaseIterable, Sendable {
    case navigation
    case interaction
    case error
    case performance
    case system
    case api
    case plugin
}

public struct SessionMetrics: Codable, Sendable {
    public let startedAt: Date?
    public let navigationCount: Int
    public let interactionCount: Int
    public let errorCount: Int
    public let performanceCount: Int
    public let systemCount: Int
    public let apiCount: Int
    public let pluginCount: Int

    public var totalEvents: Int {
        navigationCount + interactionCount + errorCount + performanceCount + systemCount + apiCount + pluginCount
    }

    public static let empty = SessionMetrics(startedAt: nil)

    public init(startedAt: Date?, navigationCount: Int = 0, interactionCount: Int = 0, errorCount: Int = 0, performanceCount: Int = 0, systemCount: Int = 0, apiCount: Int = 0, pluginCount: Int = 0) {
        self.startedAt = startedAt
        self.navigationCount = navigationCount
        self.interactionCount = interactionCount
        self.errorCount = errorCount
        self.performanceCount = performanceCount
        self.systemCount = systemCount
        self.apiCount = apiCount
        self.pluginCount = pluginCount
    }

    func incrementing(category: AnalyticsCategory) -> SessionMetrics {
        SessionMetrics(
            startedAt: startedAt,
            navigationCount: navigationCount + (category == .navigation ? 1 : 0),
            interactionCount: interactionCount + (category == .interaction ? 1 : 0),
            errorCount: errorCount + (category == .error ? 1 : 0),
            performanceCount: performanceCount + (category == .performance ? 1 : 0),
            systemCount: systemCount + (category == .system ? 1 : 0),
            apiCount: apiCount + (category == .api ? 1 : 0),
            pluginCount: pluginCount + (category == .plugin ? 1 : 0)
        )
    }
}
