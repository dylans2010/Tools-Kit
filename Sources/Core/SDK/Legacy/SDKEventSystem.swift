import Foundation
import Combine

public final class SDKEventSystem {
    nonisolated(unsafe) public static let shared = SDKEventSystem()

    private let eventSubject = PassthroughSubject<SDKEvent, Never>()
    public var events: AnyPublisher<SDKEvent, Never> { eventSubject.eraseToAnyPublisher() }

    private var eventLog: [SDKEvent] = []
    private let maxLogSize = 500
    private let logQueue = DispatchQueue(label: "com.toolskit.sdk.eventsystem", qos: .utility)

    private init() {}

    public func emit(_ event: SDKEvent) {
        eventSubject.send(event)
        appendToLog(event)
    }

    public func subscribe(handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return eventSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    public func subscribe(type: String, handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return eventSubject
            .filter { $0.type == type }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    public func recentEvents(limit: Int = 50) -> [SDKEvent] {
        return Array(eventLog.prefix(limit))
    }

    private func appendToLog(_ event: SDKEvent) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            self.eventLog.insert(event, at: 0)
            if self.eventLog.count > self.maxLogSize {
                self.eventLog = Array(self.eventLog.prefix(self.maxLogSize))
            }
        }
    }
}

public struct SDKEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: String
    public let stringPayload: [String: String]
    public let timestamp: Date
    public let source: String

    public var payload: [String: Any] { stringPayload.reduce(into: [:]) { $0[$1.key] = $1.value } }

    public init(id: UUID = UUID(), type: String, stringPayload: [String: String] = [:], timestamp: Date = Date(), source: String = "SDK") {
        self.id = id
        self.type = type
        self.stringPayload = stringPayload
        self.timestamp = timestamp
        self.source = source
    }
}
