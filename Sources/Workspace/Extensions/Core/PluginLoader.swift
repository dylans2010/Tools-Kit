import Foundation

/// Handles loading of plugins from storage and initializing them into the runtime.
final class PluginLoader {
    static let shared = PluginLoader()

    private let pluginManager = SDKPluginManager.shared

    private init() {}

    @MainActor
    func loadAllPlugins() {
        print("[PluginLoader] Initializing plugin ecosystem...")
        // SDKPluginManager already loads in its init

        let plugins = pluginManager.plugins
        for plugin in plugins where plugin.isEnabled {
            registerPlugin(plugin)
        }

        print("[PluginLoader] \(plugins.count) plugins loaded and ready.")
    }

    func registerPlugin(_ plugin: SDKPlugin) {
        print("[PluginLoader] Registered: \(plugin.name)")
    }
}
