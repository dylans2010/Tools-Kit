import Foundation
import Combine

/// Internal event bus for SDK projects.
public final class SDKEventSystem {
    public static let shared = SDKEventSystem()

    private let eventSubject = PassthroughSubject<SDKEvent, Never>()
    public var events: AnyPublisher<SDKEvent, Never> { eventSubject.eraseToAnyPublisher() }

    private init() {}

    public func emit(_ event: SDKEvent) {
        eventSubject.send(event)
    }
}

public struct SDKEvent: Identifiable {
    public let id = UUID()
    public let type: String
    public let payload: [String: Any]
    public let timestamp = Date()
}
