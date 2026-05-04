import Foundation
import Combine

/// Centralized event distribution system for the ToolsKit Plugin System.
final class PluginEventBus: ObservableObject {
    static let shared = PluginEventBus()

    private let eventSubject = PassthroughSubject<PluginEvent, Never>()

    /// Publisher for system-wide plugin events.
    var events: AnyPublisher<PluginEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// A buffer of recent events for debugging and the Dev Console.
    @Published private(set) var recentEvents: [PluginEvent] = []
    private let maxRecentEvents = 50

    private init() {}

    /// Emits a pre-constructed event.
    func emit(_ event: PluginEvent) {
        DispatchQueue.main.async {
            self.recentEvents.insert(event, at: 0)
            if self.recentEvents.count > self.maxRecentEvents {
                self.recentEvents.removeLast()
            }
            self.eventSubject.send(event)

            // Log to console for development
            print("[PluginEventBus] Emitted: \(event.type.rawValue) (\(event.id))")
        }
    }

    /// Convenience method to emit an event by type and payload.
    func emit(type: PluginAction, payload: [String: String] = [:]) {
        let event = PluginEvent(type: type, payload: payload)
        emit(event)
    }
}
