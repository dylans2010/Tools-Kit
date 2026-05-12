import Foundation

public protocol SDKPermissionManagerProtocol {
    func isScopeAuthorized(_ scope: String) -> Bool
    func grantPermission(_ scope: String)
    func revokePermission(_ scope: String)
    func listGrantedPermissions() -> [String]
}

extension SDKPermissionManager: SDKPermissionManagerProtocol {}

@MainActor
public final class SDKSecurityManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKSecurityManager()

    public struct SensitiveOperation: Identifiable, Codable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let projectID: UUID?
        public let scope: String
        public let reason: String
    }

    @Published public private(set) var sensitiveOperations: [SensitiveOperation] = []

    private var appPermissions: [UUID: Set<String>] = [:]
    private var deniedScopes: Set<String> = []
    private var projectAPIKeys: [UUID: Set<String>] = [:]

    private init() {}

    public func setPermissions(for appId: UUID, permissions: Set<String>) {
        appPermissions[appId] = permissions
    }

    public func checkPermission(for appId: UUID, scope: String) -> Bool {
        if deniedScopes.contains(scope) { return false }
        guard let permissions = appPermissions[appId] else {
            return SDKPermissionManager.shared.isScopeAuthorized(scope)
        }
        return permissions.contains("*") || permissions.contains(scope)
    }

    public func revokeAllPermissions(for appId: UUID) {
        appPermissions.removeValue(forKey: appId)
    }

    public func denyScope(_ scope: String) {
        deniedScopes.insert(scope)
    }

    public func allowScope(_ scope: String) {
        deniedScopes.remove(scope)
    }

    public func isDenied(_ scope: String) -> Bool {
        deniedScopes.contains(scope)
    }

    public func registerAPIKey(_ key: String, for projectID: UUID) {
        var keys = projectAPIKeys[projectID] ?? []
        keys.insert(key)
        projectAPIKeys[projectID] = keys
    }

    public func validateAPIKeyUsage(_ key: String?, projectID: UUID?) throws {
        guard let projectID, let key else { return }
        let keys = projectAPIKeys[projectID] ?? []
        guard keys.contains(key) else {
            throw SDKError.permissionDenied(scope: "apiKey.invalid")
        }
    }

    public func enforce(request: SDKPolicyRequest, definition: SDKSecurityScopeDefinition) throws {
        if SDKRuntimeEngine.shared.isNoSandboxModeEnabled { return }

        if deniedScopes.contains(request.scope) {
            recordSensitiveOperation(request: request, reason: "Denied scope")
            throw SDKError.permissionDenied(scope: request.scope)
        }

        if let appID = request.appID,
           let appRules = appPermissions[appID],
           !appRules.contains("*"),
           !appRules.contains(request.scope) {
            recordSensitiveOperation(request: request, reason: "App permission boundary")
            throw SDKError.permissionDenied(scope: request.scope)
        }

        guard request.allowedScopes.contains("*") || request.allowedScopes.contains(request.scope) else {
            recordSensitiveOperation(request: request, reason: "Request scope boundary")
            throw SDKError.permissionDenied(scope: request.scope)
        }

        if definition.riskLevel == .critical || definition.riskLevel == .high {
            recordSensitiveOperation(request: request, reason: "High-risk scope access")
        }

        try validateAPIKeyUsage(request.apiKey, projectID: request.projectID)
    }

    public func auditReport() -> SecurityAuditReport {
        SecurityAuditReport(
            totalAppsWithPermissions: appPermissions.count,
            globalPermissions: SDKPermissionManager.shared.listGrantedPermissions(),
            deniedScopes: Array(deniedScopes),
            timestamp: Date()
        )
    }

    private func recordSensitiveOperation(request: SDKPolicyRequest, reason: String) {
        let entry = SensitiveOperation(
            id: UUID(),
            timestamp: Date(),
            projectID: request.projectID,
            scope: request.scope,
            reason: reason
        )
        sensitiveOperations.insert(entry, at: 0)
        if sensitiveOperations.count > 1000 {
            sensitiveOperations = Array(sensitiveOperations.prefix(1000))
        }
    }
}

@MainActor
public final class SDKSecurityPolicy {
    nonisolated(unsafe) public static let shared = SDKSecurityPolicy()

    private let securityManager = SDKSecurityManager.shared

    private init() {}

    public func setPermissions(for appId: UUID, permissions: Set<String>) {
        securityManager.setPermissions(for: appId, permissions: permissions)
    }

    public func checkPermission(for appId: UUID, scope: String) -> Bool {
        securityManager.checkPermission(for: appId, scope: scope)
    }

    public func revokeAllPermissions(for appId: UUID) {
        securityManager.revokeAllPermissions(for: appId)
    }

    public func denyScope(_ scope: String) {
        securityManager.denyScope(scope)
    }

    public func allowScope(_ scope: String) {
        securityManager.allowScope(scope)
    }

    public func isDenied(_ scope: String) -> Bool {
        securityManager.isDenied(scope)
    }

    @MainActor
    public func enforceSandbox(for appId: UUID, action: String) throws {
        guard let app = PluginRuntimeEngine.shared.getApp(appId) else {
            throw SDKError.executionFailed(reason: "App not found for sandbox check")
        }
        guard app.isSandboxed else { return }
        guard securityManager.checkPermission(for: appId, scope: action) else {
            throw SDKError.permissionDenied(scope: "\(app.name):\(action)")
        }
    }

    public func auditReport() -> SecurityAuditReport {
        securityManager.auditReport()
    }
}

public struct SecurityAuditReport: Codable, Sendable {
    public let totalAppsWithPermissions: Int
    public let globalPermissions: [String]
    public let deniedScopes: [String]
    public let timestamp: Date
}
