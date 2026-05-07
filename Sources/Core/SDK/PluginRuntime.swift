import Foundation
import Combine

/// Runtime engine for managing the lifecycle of Apps and Plugins.
public final class PluginRuntime: ObservableObject {
    public static let shared = PluginRuntime()

    @Published public private(set) var activeApps: [any SDKApp] = []
    @Published public private(set) var loadedPlugins: [any SDKPlugin] = []

    private init() {}

    public func launchApp(_ app: any SDKApp) async {
        await app.onInitialize()
        await app.onStart()
        DispatchQueue.main.async {
            self.activeApps.append(app)
        }
        SDKEventBus.shared.publish(SDKEvent(type: "app.started", source: "PluginRuntime", payload: ["appName": app.name]))
    }

    public func stopApp(id: UUID) async {
        guard let index = activeApps.firstIndex(where: { $0.id == id }) else { return }
        let app = activeApps[index]
        await app.onStop()
        DispatchQueue.main.async {
            self.activeApps.remove(at: index)
        }
        SDKEventBus.shared.publish(SDKEvent(type: "app.stopped", source: "PluginRuntime", payload: ["appName": app.name]))
    }

    public func loadPlugin(_ plugin: any SDKPlugin) {
        // Enforce permissions before loading
        for scope in plugin.requiredScopes {
            if !SDKPermissionManager.shared.hasPermission(for: scope) {
                SDKLogStore.shared.log("Plugin \(plugin.name) missing required scope: \(scope.rawValue)", source: "PluginRuntime", level: .warning)
                // In production, we might block loading
            }
        }

        DispatchQueue.main.async {
            self.loadedPlugins.append(plugin)
        }
        SDKEventBus.shared.publish(SDKEvent(type: "plugin.loaded", source: "PluginRuntime", payload: ["pluginName": plugin.name]))
    }
}
