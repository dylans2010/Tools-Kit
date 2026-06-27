import Foundation

public enum MTError: Error, LocalizedError, Equatable {
    case invalidFormat
    case networkError(String)
    case tokenInvalid
    case tokenExpired
    case keychainError(Int32)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat: return "The token format is invalid."
        case .networkError(let reason): return "Network error: \(reason)"
        case .tokenInvalid: return "The pairing token is invalid."
        case .tokenExpired: return "The pairing token has expired."
        case .keychainError(let status): return "Keychain error: \(status)"
        }
    }
}
