import Foundation
import Combine

public enum SDKPluginPhase: String, Codable, CaseIterable, Sendable {
    case unloaded, loading, active, paused, updating, migrating, errored, disabled
}

public struct SDKPluginCapability: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    public var requiredPermissions: [PluginPermission]
    public var injectedServiceKey: String?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        requiredPermissions: [PluginPermission] = [],
        injectedServiceKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.requiredPermissions = requiredPermissions
        self.injectedServiceKey = injectedServiceKey
    }
}

public struct SDKPluginManifest: Identifiable, Codable, Sendable {
    public let id: UUID
    public var identifier: String
    public var displayName: String
    public var version: String
    public var author: String
    public var description: String
    public var minimumSDKVersion: String
    public var capabilities: [SDKPluginCapability]
    public var dependencies: [String]
    public var permissions: [PluginPermission]
    public var hooks: [String]
    public var category: PluginCategory
    public var iconName: String
    public var installedAt: Date
    public var updatedAt: Date

    public enum PluginCategory: String, Codable, CaseIterable, Sendable {
        case productivity, communication, development, analytics
        case automation, integration, utility, ai
    }

    public init(
        id: UUID = UUID(),
        identifier: String,
        displayName: String,
        version: String = "1.0.0",
        author: String = "",
        description: String = "",
        minimumSDKVersion: String = "2.0.0",
        capabilities: [SDKPluginCapability] = [],
        dependencies: [String] = [],
        permissions: [PluginPermission] = [],
        hooks: [String] = [],
        category: PluginCategory = .utility,
        iconName: String = "puzzlepiece.extension"
    ) {
        self.id = id
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.author = author
        self.description = description
        self.minimumSDKVersion = minimumSDKVersion
        self.capabilities = capabilities
        self.dependencies = dependencies
        self.permissions = permissions
        self.hooks = hooks
        self.category = category
        self.iconName = iconName
        self.installedAt = Date()
        self.updatedAt = Date()
    }
}

@MainActor
public final class SDKPluginLifecycleManager: ObservableObject {
    public static let shared = SDKPluginLifecycleManager()

    @Published public var manifests: [SDKPluginManifest] = []
    @Published public var phases: [UUID: SDKPluginPhase] = [:]
    @Published public var lifecycleLog: [PluginLifecycleEvent] = []

    public struct PluginLifecycleEvent: Identifiable, Codable, Sendable {
        public let id: UUID
        public let pluginIdentifier: String
        public let fromPhase: String
        public let toPhase: String
        public let timestamp: Date
    }

    private let persistenceKey = "sdk_plugin_manifests"

    private init() {
        loadManifests()
    }

    public func install(_ manifest: SDKPluginManifest) throws {
        guard !manifests.contains(where: { $0.identifier == manifest.identifier }) else {
            throw SDKError.validationError(reason: "Plugin '\(manifest.identifier)' already installed")
        }
        manifests.append(manifest)
        phases[manifest.id] = .unloaded
        logTransition(identifier: manifest.identifier, from: "none", to: SDKPluginPhase.unloaded.rawValue)
        saveManifests()
    }

    public func uninstall(identifier: String) async {
        guard let manifest = manifests.first(where: { $0.identifier == identifier }) else { return }
        if phases[manifest.id] == .active || phases[manifest.id] == .paused {
            await transition(identifier: identifier, to: .disabled)
        }
        manifests.removeAll { $0.identifier == identifier }
        phases.removeValue(forKey: manifest.id)
        SDKFeatureExposureManager.shared.retractAll(for: identifier)
        saveManifests()
    }

    public func transition(identifier: String, to phase: SDKPluginPhase) async {
        guard let index = manifests.firstIndex(where: { $0.identifier == identifier }) else { return }
        let pluginID = manifests[index].id
        let oldPhase = phases[pluginID] ?? .unloaded

        guard isTransitionValid(from: oldPhase, to: phase) else { return }

        phases[pluginID] = phase
        logTransition(identifier: identifier, from: oldPhase.rawValue, to: phase.rawValue)
        saveManifests()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.plugins",
            name: "plugin.phase.\(phase.rawValue)",
            data: ["identifier": identifier, "from": oldPhase.rawValue, "to": phase.rawValue]
        ))
    }

    public func update(identifier: String, to newVersion: String) async throws {
        guard let index = manifests.firstIndex(where: { $0.identifier == identifier }) else {
            throw SDKError.executionFailed(reason: "Plugin not found")
        }
        let previousPhase = phases[manifests[index].id] ?? .unloaded
        await transition(identifier: identifier, to: .updating)
        manifests[index].version = newVersion
        manifests[index].updatedAt = Date()
        await transition(identifier: identifier, to: previousPhase == .active ? .active : .unloaded)
        saveManifests()
    }

    public func pluginsInPhase(_ phase: SDKPluginPhase) -> [SDKPluginManifest] {
        manifests.filter { phases[$0.id] == phase }
    }

    public func phase(for identifier: String) -> SDKPluginPhase {
        guard let manifest = manifests.first(where: { $0.identifier == identifier }) else { return .unloaded }
        return phases[manifest.id] ?? .unloaded
    }

    private func isTransitionValid(from: SDKPluginPhase, to: SDKPluginPhase) -> Bool {
        switch (from, to) {
        case (.unloaded, .loading), (.loading, .active), (.loading, .errored),
             (.active, .paused), (.active, .disabled), (.active, .updating),
             (.paused, .active), (.paused, .disabled),
             (.updating, .active), (.updating, .errored),
             (.migrating, .active), (.migrating, .errored),
             (.errored, .loading), (.errored, .disabled),
             (.disabled, .loading), (.disabled, .unloaded):
            return true
        default:
            return false
        }
    }

    private func logTransition(identifier: String, from: String, to: String) {
        let event = PluginLifecycleEvent(id: UUID(), pluginIdentifier: identifier, fromPhase: from, toPhase: to, timestamp: Date())
        lifecycleLog.insert(event, at: 0)
        if lifecycleLog.count > 300 { lifecycleLog = Array(lifecycleLog.prefix(300)) }
    }

    private func saveManifests() {
        if let data = try? JSONEncoder().encode(manifests) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadManifests() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let loaded = try? JSONDecoder().decode([SDKPluginManifest].self, from: data) {
            manifests = loaded
            for m in loaded { phases[m.id] = .unloaded }
        }
    }
}
