import Foundation

/// Handles loading of plugins from storage and initializing them into the runtime.
final class PluginLoader {
    static let shared = PluginLoader()

    private var pluginManager: SDKPluginManager {
        get async {
            await MainActor.run { SDKPluginManager.shared }
        }
    }

    private init() {}

    @MainActor
    func loadAllPlugins() async {
        print("[PluginLoader] Initializing plugin ecosystem...")
        // SDKPluginManager already loads in its init

        let manager = await pluginManager
        let plugins = manager.plugins
        for plugin in plugins where plugin.isEnabled {
            registerPlugin(plugin)
        }

        print("[PluginLoader] \(plugins.count) plugins loaded and ready.")
    }

    func registerPlugin(_ plugin: SDKPlugin) {
        print("[PluginLoader] Registered: \(plugin.name)")
    }
}
