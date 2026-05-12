import Foundation
import Combine

public final class SDKEventBridge: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKEventBridge()

    private let eventSubject = PassthroughSubject<SDKEvent, Never>()
    @Published public var eventHistory: [SDKEvent] = []

    private let maxHistorySize = 1000
    private let historyQueue = DispatchQueue(label: "com.toolskit.sdk.eventbridge", qos: .utility)
    private let persistenceURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        persistenceURL = appSupport.appendingPathComponent("sdk_events.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadHistory()
    }

    // MARK: - Emit

    public func emit(type: String, payload: [String: Any]) {
        let event = SDKEvent(
            id: UUID(),
            type: type,
            stringPayload: payload.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) },
            timestamp: Date(),
            source: "SDK"
        )

        eventSubject.send(event)
        appendToHistory(event)

        SDKEventSystem.shared.emit(SDKEvent(
            id: event.id,
            type: event.type,
            stringPayload: event.stringPayload,
            timestamp: event.timestamp,
            source: event.source
        ))
    }

    // MARK: - Subscribe

    public func subscribe(type: String, handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return eventSubject
            .filter { $0.type == type }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    public func subscribeAll(handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return eventSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    // MARK: - Replay

    public func replay(from: Date, to: Date) -> [SDKEvent] {
        return eventHistory.filter { $0.timestamp >= from && $0.timestamp <= to }
    }

    // MARK: - Filter

    public func filter(type: String?, source: String?) -> [SDKEvent] {
        return eventHistory.filter { event in
            if let type = type, event.type != type { return false }
            if let source = source, event.source != source { return false }
            return true
        }
    }

    // MARK: - Clear

    public func clearHistory() {
        eventHistory.removeAll()
        persistHistory()
    }

    // MARK: - Private

    private func appendToHistory(_ event: SDKEvent) {
        eventHistory.insert(event, at: 0)
        if eventHistory.count > maxHistorySize {
            eventHistory = Array(eventHistory.prefix(maxHistorySize))
        }
        persistHistory()
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
              let events = try? JSONDecoder().decode([SDKEvent].self, from: data) else { return }
        eventHistory = events
    }
}
