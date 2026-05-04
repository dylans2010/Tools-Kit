import Foundation

/// Handles the execution of plugin logic within the system.
final class PluginRuntime {
    static let shared = PluginRuntime()

    private let sandbox = PluginSandbox.shared
    private let eventBus = PluginEventBus.shared
    private let dataStore = UnifiedDataStore.shared

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
            // Refined capability check
            let isTargeted = plugin.targetSystems.contains { target in
                target.rawValue.lowercased() == event.capability.rawValue.lowercased() || target == .global
            }

            if isTargeted {
                sandbox.execute(plugin: plugin, event: event)
            }
        }
    }

    func executeCommand(_ keyword: String, parameters: [String: String]) -> String {
        guard let plugin = PluginManager.shared.installedPlugins.first(where: { p in
            p.isEnabled && p.commands.contains { $0.keyword == keyword }
        }), let command = plugin.commands.first(where: { $0.keyword == keyword }) else {
            return "Command not found or plugin disabled."
        }

        return sandbox.executeCommand(plugin: plugin, command: command, params: parameters)
    }
}
