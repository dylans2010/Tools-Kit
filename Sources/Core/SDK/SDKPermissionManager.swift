import Foundation

/// Manages permissions and security scopes for the WorkspaceSDK.
public final class SDKPermissionManager {
    public static let shared = SDKPermissionManager()

    public enum PermissionScope: String {
        case mailRead = "mail.read"
        case mailWrite = "mail.write"
        case notebooksRead = "notebooks.read"
        case notebooksWrite = "notebooks.write"
        case meetRead = "meet.read"
        case meetWrite = "meet.write"
        case articlesRead = "articles.read"
        case articlesWrite = "articles.write"
        case systemAdmin = "system.admin"
    }

    private var grantedScopes: Set<PermissionScope> = []

    private init() {}

    public func grantScope(_ scope: PermissionScope) {
        grantedScopes.insert(scope)
    }

    public func revokeScope(_ scope: PermissionScope) {
        grantedScopes.remove(scope)
    }

    public func hasPermission(for scope: PermissionScope) -> Bool {
        // In development mode, we might allow all. For production, strict check.
        if WorkspaceSDKKernel.shared.environment.mode == .development {
            return true
        }
        return grantedScopes.contains(scope) || grantedScopes.contains(.systemAdmin)
    }

    public func enforce(scope: PermissionScope) throws {
        guard hasPermission(for: scope) else {
            throw SDKSecurityError.permissionDenied(scope.rawValue)
        }
    }
}

public enum SDKSecurityError: Error {
    case permissionDenied(String)
}
