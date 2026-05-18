import Foundation

/// Handles the execution of plugin logic within the system.
/// Orchestrates the execution pipeline: capture, evaluate, and execute or block.
final class PluginRuntime {
    static let shared = PluginRuntime()

    private let sandbox = PluginSandbox.shared
    private let eventBus = PluginEventBus.shared

    private init() {
        setupGlobalSubscribers()
    }

    private func setupGlobalSubscribers() {
        eventBus.subscribe { [weak self] event in
            self?.processEvent(event)
        }
    }

    @MainActor
    private func processEvent(_ event: PluginEvent) {
        let enabledPlugins = SDKPluginManager.shared.plugins.filter { $0.isEnabled }

        for plugin in enabledPlugins {
            // Check if plugin is subscribed to this event
            let isSubscribed = plugin.automationHooks.contains { $0 == event.action }

            if isSubscribed {
                // The sandbox now handles validation and execution/blocking logic
                // sandbox.execute(plugin: plugin, event: event) // TODO: execution logic needs alignment with SDKPlugin
            }
        }
    }
}
