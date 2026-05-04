import Foundation

/// Handles loading of plugins from storage and initializing them into the runtime.
final class PluginLoader {
    static let shared = PluginLoader()

    private let dataStore = UnifiedDataStore.shared
    private let pluginManager = PluginManager.shared

    private init() {}

    func loadAllPlugins() {
        print("[PluginLoader] Initializing plugin ecosystem...")
        // PluginManager already loads from 'installed_plugins.json' in UnifiedDataStore

        let plugins = pluginManager.installedPlugins
        for plugin in plugins where plugin.isEnabled {
            registerPlugin(plugin)
        }

        print("[PluginLoader] \(plugins.count) plugins loaded and ready.")
    }

    func registerPlugin(_ plugin: PluginDefinition) {
        // Register each command with the system CommandEngine
        for command in plugin.commands {
            CommandEngine.shared.registerPluginCommand(command, pluginName: plugin.name)
        }
        print("[PluginLoader] Registered commands for: \(plugin.name)")
    }
}
