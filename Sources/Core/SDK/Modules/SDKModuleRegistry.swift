import Foundation
import Combine

public enum SDKModuleCapability: String, Codable, CaseIterable, Hashable {
    case networking
    case storage
    case rendering
    case automation
    case authentication
    case analytics
    case messaging
    case fileSystem
    case aiProcessing
    case connectorBinding
    case pluginHosting
    case eventPublishing
    case backgroundExecution
}

public struct SDKModuleDescriptor: Identifiable, Codable, Hashable, Equatable {
    public let id: UUID
    public let identifier: String
    public let displayName: String
    public let version: String
    public var loadPriority: Int
    public var capabilities: [SDKModuleCapability]
    public var dependencies: [String]
    public var minimumSDKVersion: String = "2.0"
    public var exportedServices: [String] = []
    public init(identifier: String, displayName: String, version: String = "1.0",
                loadPriority: Int = 0, capabilities: [SDKModuleCapability] = [],
                dependencies: [String] = []) {
        self.id = UUID()
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.loadPriority = loadPriority
        self.capabilities = SDKModuleDescriptor.deduplicated(capabilities)
        self.dependencies = dependencies
    }

    public init(identifier: String, displayName: String, version: String = "1.0",
                capabilities: [SDKModuleCapability]) {
        self.id = UUID()
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.loadPriority = 0
        self.capabilities = SDKModuleDescriptor.deduplicated(capabilities)
        self.dependencies = []
    }

    private static func deduplicated(_ capabilities: [SDKModuleCapability]) -> [SDKModuleCapability] {
        var seen: Set<SDKModuleCapability> = []
        return capabilities.filter { seen.insert($0).inserted }
    }
}

public struct SDKModuleRegistrationEvent: Identifiable, Codable, Hashable {
    public let id: UUID = UUID()
    public let moduleIdentifier: String
    public let action: String
    public let timestamp: Date = Date()
}

public class SDKModuleRegistry: ObservableObject {
    public static let shared = SDKModuleRegistry()
    @Published public var modules: [SDKModuleDescriptor] = []
    @Published public var registrationLog: [SDKModuleRegistrationEvent] = []
    @Published public var activeModuleIDs: Set<UUID> = []

    private init() {}

    public func register(_ module: SDKModuleDescriptor) throws {
        modules.removeAll { $0.identifier == module.identifier }
        modules.append(module)
        registrationLog.append(SDKModuleRegistrationEvent(moduleIdentifier: module.identifier, action: "Registered"))
    }

    public func unregister(identifier: String) {
        if let mod = modules.first(where: { $0.identifier == identifier }) {
            activeModuleIDs.remove(mod.id)
            modules.removeAll { $0.identifier == identifier }
            registrationLog.append(SDKModuleRegistrationEvent(moduleIdentifier: identifier, action: "Unregistered"))
        }
    }

    public func activate(identifier: String) async throws {
        if let mod = modules.first(where: { $0.identifier == identifier }) {
            activeModuleIDs.insert(mod.id)
            registrationLog.append(SDKModuleRegistrationEvent(moduleIdentifier: identifier, action: "Activated"))
        }
    }

    public func deactivate(identifier: String) async {
        if let mod = modules.first(where: { $0.identifier == identifier }) {
            activeModuleIDs.remove(mod.id)
            registrationLog.append(SDKModuleRegistrationEvent(moduleIdentifier: identifier, action: "Deactivated"))
        }
    }

    public var module: SDKModuleDescriptor? { modules.first }
}
