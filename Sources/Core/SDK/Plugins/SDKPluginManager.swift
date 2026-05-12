import Foundation
import Combine

public struct SDKPlugin: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var version: String
    public var permissions: [PluginPermission]
    public var isEnabled: Bool
    public var installedAt: Date
    public var tools: [UUID]
    public var automationHooks: [String]
}

public enum PluginPermission: String, Codable, Sendable {
    case readData, writeData, network, notifications, fileAccess
}

@MainActor
public final class SDKPluginManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKPluginManager()

    @Published public var plugins: [SDKPlugin] = []

    private let persistenceKey = "sdk_installed_plugins"

    private init() {
        loadPlugins()
    }

    public func install(_ plugin: SDKPlugin) throws {
        guard !plugins.contains(where: { $0.id == plugin.id }) else {
            throw SDKError.validationError(reason: "Plugin \(plugin.name) is already installed")
        }

        guard AuthorizationManager.shared.canUseScopes(plugin.requiredScopes) || plugin.requiredScopes.isEmpty else {
            throw SDKError.permissionDenied(scope: plugin.requiredScopes.joined(separator: ","))
        }

        for permission in plugin.permissions {
            guard isPermissionGrantable(permission) else {
                throw SDKError.permissionDenied(scope: "plugin.\(permission.rawValue)")
            }
        }

        plugins.append(plugin)
        savePlugins()
        SDKLogStore.shared.log("Plugin installed: \(plugin.name) v\(plugin.version)", source: "SDKPluginManager", level: LogLevel.info)
    }

    public func enable(id: UUID) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            guard AuthorizationManager.shared.canUsePlugin(id: id) else {
                plugins[index].isEnabled = false
                savePlugins()
                SDKLogStore.shared.log("Plugin blocked by authorization: \(plugins[index].name)", source: "SDKPluginManager", level: LogLevel.warning)
                return
            }
            plugins[index].isEnabled = true
            savePlugins()
            SDKLogStore.shared.log("Plugin enabled: \(plugins[index].name)", source: "SDKPluginManager", level: LogLevel.info)
        }
    }

    public func disable(id: UUID) {
        if let index = plugins.firstIndex(where: { $0.id == id }) {
            plugins[index].isEnabled = false
            savePlugins()
            SDKLogStore.shared.log("Plugin disabled: \(plugins[index].name)", source: "SDKPluginManager", level: LogLevel.info)
        }
    }

    public func remove(id: UUID) {
        if let plugin = plugins.first(where: { $0.id == id }) {
            SDKLogStore.shared.log("Plugin removed: \(plugin.name)", source: "SDKPluginManager", level: LogLevel.info)
        }
        plugins.removeAll { $0.id == id }
        savePlugins()
    }

    public func executeHook(_ event: String, context: [String: Any]) async {
        let applicablePlugins = plugins.filter {
            $0.isEnabled &&
            $0.automationHooks.contains(event) &&
            AuthorizationManager.shared.canUsePlugin(id: $0.id)
        }

        for plugin in applicablePlugins {
            SDKLogStore.shared.log("Executing hook '\(event)' for plugin \(plugin.name)", source: "SDKPluginManager", level: LogLevel.info)

            for toolID in plugin.tools {
                do {
                    _ = try await SDKToolManager.shared.execute(toolID: toolID, input: context.reduce(into: [:]) { $0[$1.key] = $1.value })
                } catch {
                    SDKLogStore.shared.log("Hook execution failed for \(plugin.name): \(error.localizedDescription)", source: "SDKPluginManager", level: LogLevel.error)
                }
            }
        }
    }

    public func getPlugin(id: UUID) -> SDKPlugin? {
        return plugins.first(where: { $0.id == id })
    }

    public func updatePlugin(id: UUID, updates: (inout SDKPlugin) -> Void) {
        guard let index = plugins.firstIndex(where: { $0.id == id }) else { return }
        updates(&plugins[index])
        savePlugins()
    }

    private func isPermissionGrantable(_ permission: PluginPermission) -> Bool {
        switch permission {
        case .readData, .writeData, .notifications:
            return true
        case .network:
            return true
        case .fileAccess:
            return true
        }
    }

    private func savePlugins() {
        SDKProjectManager.shared.currentProject?.enabledPluginIDs = plugins.map { $0.id }
        try? SDKProjectManager.shared.save()

        if let data = try? JSONEncoder().encode(plugins) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadPlugins() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let loaded = try? JSONDecoder().decode([SDKPlugin].self, from: data) {
            plugins = loaded
        }
    }
}
