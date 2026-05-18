import Foundation
import Combine

public enum SDKModuleCapability: String, Codable, CaseIterable {
    case dataAccess, networking, storage, rendering, automation
    case authentication, analytics, messaging, fileSystem, aiProcessing
    case connectorBinding, pluginHosting, eventPublishing, backgroundExecution
}

public struct SDKModuleDescriptor: Identifiable, Codable, Hashable {
    public let id: UUID
    public var identifier: String
    public var displayName: String
    public var version: String
    public var minimumSDKVersion: String
    public var capabilities: [SDKModuleCapability]
    public var dependencies: [String]
    public var exportedServices: [String]
    public var isEnabled: Bool
    public var loadPriority: Int
    public var registeredAt: Date
    public var requiredScopes: [String]

    public init(
        id: UUID = UUID(),
        identifier: String,
        displayName: String,
        version: String = "1.0.0",
        minimumSDKVersion: String = "2.0.0",
        capabilities: [SDKModuleCapability] = [],
        dependencies: [String] = [],
        exportedServices: [String] = [],
        isEnabled: Bool = true,
        loadPriority: Int = 100,
        requiredScopes: [String] = []
    ) {
        self.id = id
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.minimumSDKVersion = minimumSDKVersion
        self.capabilities = capabilities
        self.dependencies = dependencies
        self.exportedServices = exportedServices
        self.isEnabled = isEnabled
        self.loadPriority = loadPriority
        self.registeredAt = Date()
        self.requiredScopes = requiredScopes
    }
}

public protocol SDKModuleProvider {
    var descriptor: SDKModuleDescriptor { get }
    func activate(context: SDKContext) async throws
    func deactivate() async
    func healthCheck() -> Bool
}

@MainActor
public final class SDKModuleRegistry: ObservableObject {
    public static let shared = SDKModuleRegistry()

    @Published public var modules: [SDKModuleDescriptor] = []
    @Published public var activeModuleIDs: Set<UUID> = []
    @Published public var registrationLog: [ModuleRegistrationEvent] = []

    private var providers: [String: SDKModuleProvider] = [:]
    private let persistenceKey = "sdk_module_registry"

    public struct ModuleRegistrationEvent: Identifiable, Codable {
        public let id: UUID
        public let moduleIdentifier: String
        public let action: String
        public let timestamp: Date
    }

    private init() {
        loadModules()
    }

    public func register(_ descriptor: SDKModuleDescriptor, provider: SDKModuleProvider? = nil) throws {
        guard !modules.contains(where: { $0.identifier == descriptor.identifier }) else {
            throw SDKError.validationError(reason: "Module '\(descriptor.identifier)' is already registered")
        }

        let unmet = unmetDependencies(for: descriptor)
        guard unmet.isEmpty else {
            throw SDKError.validationError(reason: "Unmet dependencies: \(unmet.joined(separator: ", "))")
        }

        var resolvedDescriptor = descriptor
        if !AuthorizationManager.shared.canAccessModule(id: descriptor.identifier) {
            resolvedDescriptor.isEnabled = false
            SDKLogStore.shared.log(
                "Module '\(descriptor.identifier)' registered in blocked state (insufficient authorization)",
                source: "SDKModuleRegistry",
                level: .warning
            )
        }

        modules.append(resolvedDescriptor)
        if let provider = provider {
            providers[descriptor.identifier] = provider
        }
        modules.sort { $0.loadPriority < $1.loadPriority }

        logEvent(moduleIdentifier: descriptor.identifier, action: "registered")
        saveModules()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.modules",
            name: "module.registered",
            data: ["identifier": descriptor.identifier, "version": descriptor.version]
        ))
    }

    public func unregister(identifier: String) {
        activeModuleIDs.subtract(modules.filter { $0.identifier == identifier }.map(\.id))
        modules.removeAll { $0.identifier == identifier }
        providers.removeValue(forKey: identifier)
        logEvent(moduleIdentifier: identifier, action: "unregistered")
        saveModules()
    }

    public func activate(identifier: String) async throws {
        guard let index = modules.firstIndex(where: { $0.identifier == identifier }) else {
            throw SDKError.executionFailed(reason: "Module '\(identifier)' not found")
        }

        guard AuthorizationManager.shared.canAccessModule(id: identifier) else {
            throw SDKError.permissionDenied(scope: modules[index].requiredScopes.joined(separator: ","))
        }

        for dep in modules[index].dependencies {
            guard activeModuleIDs.contains(where: { id in modules.contains(where: { $0.id == id && $0.identifier == dep }) }) else {
                try await activate(identifier: dep)
                break
            }
        }

        if let provider = providers[identifier] {
            try await provider.activate(context: SDKContext.global())
        }

        activeModuleIDs.insert(modules[index].id)
        modules[index].isEnabled = true
        logEvent(moduleIdentifier: identifier, action: "activated")
        saveModules()
    }

    public func deactivate(identifier: String) async {
        guard let index = modules.firstIndex(where: { $0.identifier == identifier }) else { return }

        let dependents = modules.filter { $0.dependencies.contains(identifier) && activeModuleIDs.contains($0.id) }
        for dependent in dependents {
            await deactivate(identifier: dependent.identifier)
        }

        if let provider = providers[identifier] {
            await provider.deactivate()
        }

        activeModuleIDs.remove(modules[index].id)
        modules[index].isEnabled = false
        logEvent(moduleIdentifier: identifier, action: "deactivated")
        saveModules()
    }

    public func module(for identifier: String) -> SDKModuleDescriptor? {
        modules.first { $0.identifier == identifier }
    }

    public func modules(withCapability capability: SDKModuleCapability) -> [SDKModuleDescriptor] {
        modules.filter { $0.capabilities.contains(capability) }
    }

    public func resolvedLoadOrder() -> [SDKModuleDescriptor] {
        var resolved: [SDKModuleDescriptor] = []
        var visited = Set<String>()

        func visit(_ mod: SDKModuleDescriptor) {
            guard !visited.contains(mod.identifier) else { return }
            visited.insert(mod.identifier)
            for dep in mod.dependencies {
                if let depMod = modules.first(where: { $0.identifier == dep }) {
                    visit(depMod)
                }
            }
            resolved.append(mod)
        }

        for mod in modules.sorted(by: { $0.loadPriority < $1.loadPriority }) {
            visit(mod)
        }
        return resolved
    }

    public func unmetDependencies(for descriptor: SDKModuleDescriptor) -> [String] {
        descriptor.dependencies.filter { dep in
            !modules.contains(where: { $0.identifier == dep })
        }
    }

    public func compatibilityCheck(_ descriptor: SDKModuleDescriptor) -> [String] {
        var issues: [String] = []
        let currentVersion = SDKEnvironment.shared.configuration.sdkVersion
        if descriptor.minimumSDKVersion > currentVersion {
            issues.append("Requires SDK \(descriptor.minimumSDKVersion), current is \(currentVersion)")
        }
        let unmet = unmetDependencies(for: descriptor)
        issues.append(contentsOf: unmet.map { "Missing dependency: \($0)" })
        return issues
    }

    private func logEvent(moduleIdentifier: String, action: String) {
        let event = ModuleRegistrationEvent(id: UUID(), moduleIdentifier: moduleIdentifier, action: action, timestamp: Date())
        registrationLog.insert(event, at: 0)
        if registrationLog.count > 200 {
            registrationLog = Array(registrationLog.prefix(200))
        }
    }

    private func saveModules() {
        if let data = try? JSONEncoder().encode(modules) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadModules() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let loaded = try? JSONDecoder().decode([SDKModuleDescriptor].self, from: data) {
            modules = loaded
            activeModuleIDs = Set(loaded.filter(\.isEnabled).map(\.id))
        }
    }
}
