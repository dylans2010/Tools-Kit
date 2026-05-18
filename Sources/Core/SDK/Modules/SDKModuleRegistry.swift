import Foundation
import Combine

public enum SDKModuleCapability: String, Codable, CaseIterable, Hashable {
    case dataAccess
    case externalAPICall
    case automations
    case emails
    case read
    case write
}

public struct SDKModuleDescriptor: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public var capabilities: [SDKModuleCapability]
    public init(id: String, name: String, version: String = "1.0",
                capabilities: [SDKModuleCapability] = []) {
        self.id = id; self.name = name
        self.version = version; self.capabilities = capabilities
    }
}

public class SDKModuleRegistry: ObservableObject {
    public static let shared = SDKModuleRegistry()
    @Published public var modules: [SDKModuleDescriptor] = []
    @Published public var registrationLog: [String] = []
    private init() {}
    public func register(_ module: SDKModuleDescriptor) {
        modules.append(module)
        registrationLog.append("Registered \(module.name)")
    }
    public var module: SDKModuleDescriptor? { modules.first }
}
