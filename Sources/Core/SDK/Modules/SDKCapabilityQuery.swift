import Foundation

@MainActor
public final class SDKCapabilityQuery {
    nonisolated(unsafe) public static let shared = SDKCapabilityQuery()

    private init() {}

    public func modulesProviding(capability: SDKModuleCapability) -> [SDKModuleDescriptor] {
        SDKModuleRegistry.shared.modules.filter { $0.capabilities.contains(capability) && $0.isEnabled }
    }

    public func isCapabilityAvailable(_ capability: SDKModuleCapability) -> Bool {
        !modulesProviding(capability: capability).isEmpty
    }

    public func activeCapabilities() -> Set<SDKModuleCapability> {
        let active = SDKModuleRegistry.shared.modules.filter { $0.isEnabled }
        return Set(active.flatMap(\.capabilities))
    }

    public func capabilityMap() -> [SDKModuleCapability: [String]] {
        var map: [SDKModuleCapability: [String]] = [:]
        for module in SDKModuleRegistry.shared.modules where module.isEnabled {
            for cap in module.capabilities {
                map[cap, default: []].append(module.identifier)
            }
        }
        return map
    }

    public func resolve(requirements: [SDKModuleCapability]) -> CapabilityResolution {
        var satisfied: [SDKModuleCapability] = []
        var missing: [SDKModuleCapability] = []

        for req in requirements {
            if isCapabilityAvailable(req) {
                satisfied.append(req)
            } else {
                missing.append(req)
            }
        }

        return CapabilityResolution(satisfied: satisfied, missing: missing)
    }

    public struct CapabilityResolution: Sendable {
        public let satisfied: [SDKModuleCapability]
        public let missing: [SDKModuleCapability]

        public var isFullySatisfied: Bool { missing.isEmpty }
    }
}
