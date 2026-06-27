import Foundation

public enum PCError: Error, LocalizedError, Equatable {
    case codeInvalid
    case rateLimited(Int)
    case gatewayLocked
    case networkFailure(String)
    case exchangeFailed(String)
    case keychainError(Int32)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .codeInvalid: return "The pairing code is incorrect or has expired."
        case .rateLimited(let retryAfter): return "Too many attempts. Please try again in \(retryAfter) seconds."
        case .gatewayLocked: return "Gateway is locked due to too many failed attempts. Restart the Gateway."
        case .networkFailure(let reason): return "Network error: \(reason)"
        case .exchangeFailed(let reason): return "Credential exchange failed: \(reason)"
        case .keychainError(let status): return "Keychain error: \(status)"
        case .invalidResponse: return "The gateway returned an invalid response."
        }
    }
}
