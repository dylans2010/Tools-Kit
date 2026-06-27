import Foundation

public enum LocalApprovalError: Error, LocalizedError, Equatable {
    case connectionFailed(String)
    case approvalTimeout
    case approvalDenied
    case permanentlyBlocked
    case exchangeFailed(String)
    case keychainError(Int32)
    case invalidMessage

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason): return "Connection failed: \(reason)"
        case .approvalTimeout: return "Approval timed out."
        case .approvalDenied: return "Approval request was denied."
        case .permanentlyBlocked: return "This device has been permanently blocked by the Mac."
        case .exchangeFailed(let reason): return "Credential exchange failed: \(reason)"
        case .keychainError(let status): return "Keychain error: \(status)"
        case .invalidMessage: return "Received an invalid message from the gateway."
        }
    }
}
