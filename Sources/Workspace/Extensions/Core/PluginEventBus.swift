import Foundation
import Combine

/// Centralized event bus for both core systems and plugins.
final class PluginEventBus {
    static let shared = PluginEventBus()

    private let subject = PassthroughSubject<PluginEvent, Never>()
    private let queue = DispatchQueue(label: "io.toolskit.eventbus")

    private init() {}

    /// Emits an event to all subscribers.
    func emit(_ event: PluginEvent) {
        queue.async {
            print("[EventBus] Emitting: \(event.capability.rawValue).\(event.action)")
            self.subject.send(event)
        }
    }

    /// Subscribes to events.
    func subscribe(onReceive: @escaping (PluginEvent) -> Void) -> AnyCancellable {
        return subject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: onReceive)
    }

    /// Filters and subscribes to specific events.
    func subscribe(capability: PluginCapability, action: String? = nil, onReceive: @escaping (PluginEvent) -> Void) -> AnyCancellable {
        return subject
            .filter { event in
                let capabilityMatch = event.capability == capability
                let actionMatch = action == nil || event.action == action
                return capabilityMatch && actionMatch
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: onReceive)
    }
}

