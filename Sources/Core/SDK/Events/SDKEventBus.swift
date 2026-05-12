import Foundation
import Combine

/// Protocol for the SDK event bus.
public protocol SDKEventBusProtocol {
    func publish(_ event: SDKBusEvent)
    func subscribe(channel: String, handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable
    func subscribeAll(handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable
}

/// Unified publish/subscribe event bus for real-time communication across SDK modules.
/// Replaces fragmented event systems with a single, consistent bus.
public final class SDKEventBus: SDKEventBusProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKEventBus()

    @Published public private(set) var isRunning = false
    @Published public private(set) var eventHistory: [SDKBusEvent] = []
    @Published public private(set) var totalEventsProcessed: Int = 0

    private let subject = PassthroughSubject<SDKBusEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let historyLimit: Int = 500
    private let historyQueue = DispatchQueue(label: "com.toolskit.sdk.eventbus", qos: .utility)
    private let persistenceURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let sdkDir = appSupport.appendingPathComponent("WorkspaceSDK")
        if !FileManager.default.fileExists(atPath: sdkDir.path) {
            try? FileManager.default.createDirectory(at: sdkDir, withIntermediateDirectories: true)
        }
        persistenceURL = sdkDir.appendingPathComponent("event_history.json")
    }

    // MARK: - Lifecycle

    public func start() {
        isRunning = true
        loadHistory()
    }

    public func stop() {
        isRunning = false
        persistHistory()
    }

    // MARK: - Publish

    public func publish(_ event: SDKBusEvent) {
        guard isRunning else { return }
        subject.send(event)
        appendToHistory(event)
        totalEventsProcessed += 1

        // Bridge to legacy event systems
        SDKEventBridge.shared.emit(type: event.name, payload: event.data)
    }

    // MARK: - Subscribe

    public func subscribe(channel: String, handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable {
        return subject
            .filter { $0.channel == channel }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    public func subscribe(name: String, handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable {
        return subject
            .filter { $0.name == name }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    public func subscribeAll(handler: @escaping (SDKBusEvent) -> Void) -> AnyCancellable {
        return subject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    // MARK: - Query

    public func recentEvents(limit: Int = 50) -> [SDKBusEvent] {
        return Array(eventHistory.prefix(limit))
    }

    public func events(forChannel channel: String) -> [SDKBusEvent] {
        return eventHistory.filter { $0.channel == channel }
    }

    public func events(from: Date, to: Date) -> [SDKBusEvent] {
        return eventHistory.filter { $0.timestamp >= from && $0.timestamp <= to }
    }

    public func clearHistory() {
        eventHistory.removeAll()
        persistHistory()
    }

    // MARK: - Private

    private func appendToHistory(_ event: SDKBusEvent) {
        eventHistory.insert(event, at: 0)
        if eventHistory.count > historyLimit {
            eventHistory = Array(eventHistory.prefix(historyLimit))
        }
    }

    private func persistHistory() {
        let events = eventHistory
        historyQueue.async { [weak self] in
            guard let url = self?.persistenceURL else { return }
            if let data = try? JSONEncoder().encode(events) {
                try? data.write(to: url)
            }
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let events = try? JSONDecoder().decode([SDKBusEvent].self, from: data) else { return }
        eventHistory = events
    }
}

// MARK: - Bus Event

public struct SDKBusEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let channel: String
    public let name: String
    public let data: [String: String]
    public let source: String
    public let timestamp: Date

    public init(
        channel: String,
        name: String,
        data: [String: String] = [:],
        source: String = "SDK"
    ) {
        self.id = UUID()
        self.channel = channel
        self.name = name
        self.data = data
        self.source = source
        self.timestamp = Date()
    }
}
