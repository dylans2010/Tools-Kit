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

    private func processEvent(_ event: PluginEvent) {
        let enabledPlugins = PluginManager.shared.installedPlugins.filter { $0.isEnabled }

        for plugin in enabledPlugins {
            // Check if plugin is subscribed to this event
            let isSubscribed = plugin.actions.contains { $0.rawValue == event.action }

            if isSubscribed {
                // The sandbox now handles validation and execution/blocking logic
                sandbox.execute(plugin: plugin, event: event)
            }
        }

        // Connectors Execution (NEW)
        let enabledConnectors = ConnectorManager.shared.connectors.filter { $0.isEnabled }
        for connector in enabledConnectors {
            for flow in connector.flows {
                if flow.trigger.type == .event && flow.trigger.config["action"] == event.action {
                    ConnectorFlowEngine.shared.executeFlow(flow, connector: connector, initialPayload: event.payload)
                }
            }
        }
    }
}
