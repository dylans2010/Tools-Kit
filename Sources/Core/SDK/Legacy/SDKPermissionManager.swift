import Foundation

/// Handles scope validation and the new sdk.developer.noSandbox scope.
public final class SDKPermissionManager {
    public static let shared = SDKPermissionManager()

    // New SDK-specific scopes
    public static let noSandboxScope = "sdk.developer.noSandbox"

    private init() {}

    public func validateProjectScopes(_ project: SDKProjectLegacy) throws {
        for scope in project.requiredScopes {
            if !isScopeAuthorized(scope) {
                throw SDKError.permissionDenied(scope: scope)
            }
        }
    }

    public func isScopeAuthorized(_ scope: String) -> Bool {
        // In a real app, this would check against a user-granted permission database
        return true
    }
}

public enum SDKError: Error, LocalizedError {
    case permissionDenied(scope: String)
    case executionFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let scope): return "Permission denied for scope: \(scope)"
        case .executionFailed(let reason): return "Execution failed: \(reason)"
        }
    }
}
