import Foundation

/// Handles modular structure for SDK apps, allowing feature-based isolation.
public final class SDKModuleSystem {
    public static let shared = SDKModuleSystem()

    private var modules: [String: SDKModule] = [:]

    private init() {}

    public func registerModule(_ module: SDKModule) {
        modules[module.id] = module
        SDKLogStore.shared.log("Module registered: \(module.id)", source: "SDKModuleSystem", level: .info)
    }

    public func loadModule(id: String) throws -> SDKModule {
        guard let module = modules[id] else {
            throw SDKError.executionFailed(reason: "Module \(id) not found")
        }
        return module
    }
}

public protocol SDKModule {
    var id: String { get }
    var version: String { get }
    func initialize() async throws
}
