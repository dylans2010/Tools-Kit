import Foundation

/// Protocol for the SDK permission/security manager.
public protocol SDKPermissionManagerProtocol {
    func isScopeAuthorized(_ scope: String) -> Bool
    func grantPermission(_ scope: String)
    func revokePermission(_ scope: String)
    func listGrantedPermissions() -> [String]
}

/// Enhanced security layer for the SDK.
/// Manages scoped access control, plugin sandboxing, and data isolation.
extension SDKPermissionManager: SDKPermissionManagerProtocol {}

/// Security policy enforcement for SDK apps and plugins.
public final class SDKSecurityPolicy {
    public static let shared = SDKSecurityPolicy()

    private var appPermissions: [UUID: Set<String>] = [:]
    private var deniedScopes: Set<String> = []
    private let lock = NSRecursiveLock()

    private init() {}

    // MARK: - App-Level Permissions

    public func setPermissions(for appId: UUID, permissions: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        appPermissions[appId] = permissions
    }

    public func checkPermission(for appId: UUID, scope: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if deniedScopes.contains(scope) { return false }

        guard let permissions = appPermissions[appId] else {
            return SDKPermissionManager.shared.isScopeAuthorized(scope)
        }

        if permissions.contains("*") { return true }
        return permissions.contains(scope)
    }

    public func revokeAllPermissions(for appId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        appPermissions.removeValue(forKey: appId)
    }

    // MARK: - Global Deny List

    public func denyScope(_ scope: String) {
        lock.lock()
        defer { lock.unlock() }
        deniedScopes.insert(scope)
    }

    public func allowScope(_ scope: String) {
        lock.lock()
        defer { lock.unlock() }
        deniedScopes.remove(scope)
    }

    public func isDenied(_ scope: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return deniedScopes.contains(scope)
    }

    // MARK: - Sandbox Enforcement

    public func enforceSandbox(for appId: UUID, action: String) throws {
        guard let app = PluginRuntimeEngine.shared.getApp(appId) else {
            throw SDKError.executionFailed(reason: "App not found for sandbox check")
        }

        guard app.isSandboxed else { return }

        guard checkPermission(for: appId, scope: action) else {
            throw SDKError.permissionDenied(scope: "\(app.name):\(action)")
        }
    }

    // MARK: - Audit

    public func auditReport() -> SecurityAuditReport {
        lock.lock()
        defer { lock.unlock() }

        let totalApps = appPermissions.count
        let deniedCount = deniedScopes.count
        let globalPerms = SDKPermissionManager.shared.listGrantedPermissions()

        return SecurityAuditReport(
            totalAppsWithPermissions: totalApps,
            globalPermissions: globalPerms,
            deniedScopes: Array(deniedScopes),
            timestamp: Date()
        )
    }
}

public struct SecurityAuditReport: Codable {
    public let totalAppsWithPermissions: Int
    public let globalPermissions: [String]
    public let deniedScopes: [String]
    public let timestamp: Date
}
