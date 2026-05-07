import Foundation
import Combine

/// A real-time event bus for WorkspaceSDK.
/// Supports global publish/subscribe for cross-module communication.
public final class SDKEventBus {
    public static let shared = SDKEventBus()

    private let subject = PassthroughSubject<SDKEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    public func publish(_ event: SDKEvent) {
        subject.send(event)
    }

    public func subscribe(to type: String? = nil, handler: @escaping (SDKEvent) -> Void) -> AnyCancellable {
        return subject
            .filter { type == nil || $0.type == type }
            .sink { event in
                handler(event)
            }
    }
}

/// Structured event model for the SDK.
public struct SDKEvent {
    public let type: String
    public let source: String
    public let payload: [String: Any]
    public let timestamp: Date

    public init(type: String, source: String, payload: [String: Any] = [:]) {
        self.type = type
        self.source = source
        self.payload = payload
        self.timestamp = Date()
    }
}
