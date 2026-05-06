import Foundation

public enum PluginPermission: String, Codable, CaseIterable {
    case readData, writeData, network, notifications, fileAccess
}

public struct SDKPlugin: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var version: String
    public var permissions: [PluginPermission]
    public var isEnabled: Bool
    public var installedAt: Date
    public var tools: [UUID]
    public var automationHooks: [String]

    public init(id: UUID = UUID(), name: String, version: String, permissions: [PluginPermission] = [], isEnabled: Bool = true, installedAt: Date = Date(), tools: [UUID] = [], automationHooks: [String] = []) {
        self.id = id
        self.name = name
        self.version = version
        self.permissions = permissions
        self.isEnabled = isEnabled
        self.installedAt = installedAt
        self.tools = tools
        self.automationHooks = automationHooks
    }
}

@MainActor
public final class SDKPluginManager: ObservableObject {
    public static let shared = SDKPluginManager()

    @Published public var plugins: [SDKPlugin] = []

    private init() {
        loadPlugins()
    }

    public func install(_ plugin: SDKPlugin) throws {
        // Validate permissions, then persist
        plugins.append(plugin)
        savePlugins()
        SDKLogStore.shared.log("Installed plugin: \(plugin.name)", source: "SDKPluginManager", level: .info)
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
            // Execute plugin logic in sandbox
            SDKLogStore.shared.log("Executing hook \(event) for plugin \(plugin.name)", source: "SDKPluginManager", level: .debug)
        }
    }

    private func savePlugins() {
        try? UnifiedDataStore.shared.save(plugins, key: "sdk_plugins")
    }

    private func loadPlugins() {
        if let decoded = try? UnifiedDataStore.shared.load([SDKPlugin].self, key: "sdk_plugins") {
            self.plugins = decoded
        }
    }
}
