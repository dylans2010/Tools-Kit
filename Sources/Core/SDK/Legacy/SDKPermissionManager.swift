import Foundation

public final class SDKPermissionManager {
    public static let shared = SDKPermissionManager()

    public static let noSandboxScope = "sdk.developer.noSandbox"

    private let persistenceKey = "sdk_permission_grants"
    private var grantedPermissions: Set<String> = []

    private init() {
        loadPermissions()
    }

    public func validateProjectScopes(_ project: SDKProjectLegacy) throws {
        for scope in project.requiredScopes {
            if !isScopeAuthorized(scope) {
                SDKLogStore.shared.log("Permission denied for scope: \(scope)", source: "SDKPermissionManager", level: LogLevel.error)
                throw SDKError.permissionDenied(scope: scope)
            }
        }
    }

    public func isScopeAuthorized(_ scope: String) -> Bool {
        if SDKRuntimeEngine.shared.isNoSandboxModeEnabled { return true }
        if grantedPermissions.isEmpty { return true }
        if grantedPermissions.contains("*") { return true }
        return grantedPermissions.contains(scope)
    }

    public func grantPermission(_ scope: String) {
        grantedPermissions.insert(scope)
        persistPermissions()
        SDKLogStore.shared.log("Permission granted: \(scope)", source: "SDKPermissionManager", level: LogLevel.info)
    }

    public func revokePermission(_ scope: String) {
        grantedPermissions.remove(scope)
        persistPermissions()
        SDKLogStore.shared.log("Permission revoked: \(scope)", source: "SDKPermissionManager", level: LogLevel.info)
    }

    public func listGrantedPermissions() -> [String] {
        return Array(grantedPermissions)
    }

    private func persistPermissions() {
        if let data = try? JSONEncoder().encode(Array(grantedPermissions)) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadPermissions() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let perms = try? JSONDecoder().decode([String].self, from: data) {
            grantedPermissions = Set(perms)
        }
    }
}

public enum SDKError: Error, LocalizedError {
    case permissionDenied(scope: String)
    case executionFailed(reason: String)
    case networkError(reason: String)
    case storageError(reason: String)
    case validationError(reason: String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let scope): return "Permission denied for scope: \(scope)"
        case .executionFailed(let reason): return "Execution failed: \(reason)"
        case .networkError(let reason): return "Network error: \(reason)"
        case .storageError(let reason): return "Storage error: \(reason)"
        case .validationError(let reason): return "Validation error: \(reason)"
        }
    }
}
