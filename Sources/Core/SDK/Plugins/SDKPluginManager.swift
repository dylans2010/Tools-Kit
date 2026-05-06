import Foundation
import Combine

public struct SDKPlugin: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var version: String
    public var permissions: [PluginPermission]
    public var isEnabled: Bool
    public var installedAt: Date
    public var tools: [UUID]
    public var automationHooks: [String]
}

public enum PluginPermission: String, Codable {
    case readData, writeData, network, notifications, fileAccess
}

@MainActor
public final class SDKPluginManager: ObservableObject {
    public static let shared = SDKPluginManager()

    @Published public var plugins: [SDKPlugin] = []

    private init() {
        loadPlugins()
    }

    public func install(_ plugin: SDKPlugin) throws {
        // Validate permissions (mock)
        plugins.append(plugin)
        savePlugins()
        SDKLogStore.shared.log("Plugin installed: \(plugin.name)", source: "SDKPluginManager", level: .info)
    }

    public func enable(id: UUID) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].isEnabled = true
            savePlugins()
        }
    }

    public func disable(id: UUID) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].isEnabled = false
            savePlugins()
        }
    }

    public func remove(id: UUID) {
        plugins.removeAll { $0.id == id }
        savePlugins()
    }

    public func executeHook(_ event: String, context: [String: Any]) async {
        for plugin in plugins where plugin.isEnabled && plugin.automationHooks.contains(event) {
            SDKLogStore.shared.log("Executing hook '\(event)' for plugin \(plugin.name)", source: "SDKPluginManager", level: .info)
            // Plugin logic execution would go here
        }
    }

    private func savePlugins() {
        SDKProjectManager.shared.currentProject?.enabledPluginIDs = plugins.map { $0.id }
        try? SDKProjectManager.shared.save()
    }

    private func loadPlugins() {
        // Mock some plugins for the catalog
    }
}
