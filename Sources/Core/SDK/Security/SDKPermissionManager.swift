import Foundation

/// Protocol for the SDK permission manager.
public protocol SDKPermissionManagerProtocol {
    func isScopeAuthorized(_ scope: String) -> Bool
    func grantPermission(_ scope: String)
    func revokePermission(_ scope: String)
    func listGrantedPermissions() -> [String]
}

/// Centralized security and permission management for the WorkspaceSDK.
/// Enforces scoped access to system resources and user data.
public final class SDKPermissionManager: SDKPermissionManagerProtocol {
    public static let shared = SDKPermissionManager()

    public static let noSandboxScope = "sdk.developer.noSandbox"
    private let persistenceKey = "sdk_permission_grants_v2"
    private var grantedPermissions: Set<String> = []
    private let lock = NSRecursiveLock()

    private init() {
        loadPermissions()
        // Grant default basic permissions
        grantPermission("sdk.basic.read")
    }

    // MARK: - Authorization

    public func isScopeAuthorized(_ scope: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if grantedPermissions.contains("*") || grantedPermissions.contains("admin") {
            return true
        }

        // Handle hierarchical scopes (e.g., 'mail.*' covers 'mail.read')
        let parts = scope.split(separator: ".")
        if parts.count > 1 {
            let parentScope = parts.dropLast().joined(separator: ".") + ".*"
            if grantedPermissions.contains(parentScope) {
                return true
            }
        }

        return grantedPermissions.contains(scope)
    }

    // MARK: - Management

    public func grantPermission(_ scope: String) {
        lock.lock()
        grantedPermissions.insert(scope)
        persistPermissions()
        lock.unlock()

        Task { @MainActor in
            await SDKLogStore.shared.log("Permission granted: \(scope)", source: "SDKPermissionManager", level: .info)
            SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.security", name: "permission.granted", data: ["scope": scope]))
        }
    }

    public func revokePermission(_ scope: String) {
        lock.lock()
        grantedPermissions.remove(scope)
        persistPermissions()
        lock.unlock()

        Task { @MainActor in
            await SDKLogStore.shared.log("Permission revoked: \(scope)", source: "SDKPermissionManager", level: .info)
            SDKEventBus.shared.publish(SDKBusEvent(channel: "sdk.security", name: "permission.revoked", data: ["scope": scope]))
        }
    }

    public func listGrantedPermissions() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(grantedPermissions).sorted()
    }

    // MARK: - Persistence

    private func persistPermissions() {
        if let data = try? JSONEncoder().encode(Array(grantedPermissions)) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadPermissions() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let perms = try? JSONDecoder().decode([String].self, from: data) {
            grantedPermissions = Set(perms)
        } else {
            // Fallback to legacy if available
            if let legacyData = UserDefaults.standard.data(forKey: "sdk_permission_grants"),
               let legacyPerms = try? JSONDecoder().decode([String].self, from: legacyData) {
                grantedPermissions = Set(legacyPerms)
            }
        }
    }
}

// MARK: - Security Manager Extension

extension SDKSecurityManager {
    public func validateAccess(to scope: String) throws {
        guard SDKPermissionManager.shared.isScopeAuthorized(scope) else {
            throw SDKError.permissionDenied(scope: scope)
        }
    }
}
