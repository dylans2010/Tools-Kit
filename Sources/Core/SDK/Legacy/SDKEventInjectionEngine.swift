import Foundation

/// Injects SDK events into the global EventBus.
/// Ensures plugins and connectors can react to SDK actions in real-time.
public final class SDKEventInjectionEngine {
    public static let shared = SDKEventInjectionEngine()

    private init() {}

    public func broadcast(action: SDKAction) {
        let event = PluginEvent(
            id: UUID(),
            capability: .workspaceEvent,
            action: "sdk_action_executed",
            payload: ["action": "\(action)"],
            timestamp: Date()
        )

        PluginEventBus.shared.emit(event)
        Task { @MainActor in
            await SDKLogStore.shared.log("Broadcasted SDK event: \(action)", source: "SDKEventInjectionEngine", level: .info)
        }
    }
}
