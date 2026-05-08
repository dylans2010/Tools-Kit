import Foundation

/// Unified error type for the WorkspaceSDK.
public enum SDKError: Error, LocalizedError {
    case permissionDenied(scope: String)
    case executionFailed(reason: String)
    case networkError(reason: String)
    case storageError(reason: String)
    case validationError(reason: String)
    case notFound(path: String)
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let scope): return "Permission denied for scope: \(scope)"
        case .executionFailed(let reason): return "Execution failed: \(reason)"
        case .networkError(let reason): return "Network error: \(reason)"
        case .storageError(let reason): return "Storage error: \(reason)"
        case .validationError(let reason): return "Validation error: \(reason)"
        case .notFound(let path): return "Resource not found at: \(path)"
        case .unauthorized: return "Unauthorized access"
        }
    }
}
