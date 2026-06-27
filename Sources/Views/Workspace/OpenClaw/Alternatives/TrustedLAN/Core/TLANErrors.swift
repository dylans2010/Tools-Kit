import Foundation
public enum TLANError: Error, LocalizedError, Equatable {
    case discoveryFailed(String), connectionFailed(String), challengeTimeout, invalidChallenge, hmacComputationFailed, approvalDenied, approvalTimeout, exchangeFailed(String), keychainError(Int32), tokenExpired, invalidMessage
    public var errorDescription: String? {
        switch self {
        case .discoveryFailed(let r): return "Discovery failed: \(r)"
        case .connectionFailed(let r): return "Connection failed: \(r)"
        case .challengeTimeout: return "Challenge timeout"
        case .invalidChallenge: return "Invalid challenge"
        case .hmacComputationFailed: return "HMAC failed"
        case .approvalDenied: return "Approval denied"
        case .approvalTimeout: return "Approval timeout"
        case .exchangeFailed(let r): return "Exchange failed: \(r)"
        case .keychainError(let s): return "Keychain error: \(s)"
        case .tokenExpired: return "Token expired"
        case .invalidMessage: return "Invalid message"
        }
    }
}
