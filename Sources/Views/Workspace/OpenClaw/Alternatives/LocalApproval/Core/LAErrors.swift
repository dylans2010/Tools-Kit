import Foundation

public struct LocalApprovalError: Error, LocalizedError, Equatable {
    public enum Kind: Equatable {
        case connectionFailed(String)
        case approvalTimeout
        case approvalDenied
        case permanentlyBlocked
        case exchangeFailed(String)
        case keychainError(Int32)
        case invalidMessage
    }

    public let kind: Kind

    public var errorDescription: String? {
        switch kind {
        case .connectionFailed(let reason): return "Connection failed: \(reason)"
        case .approvalTimeout: return "Approval timed out."
        case .approvalDenied: return "Approval request was denied."
        case .permanentlyBlocked: return "This device has been permanently blocked by the Mac."
        case .exchangeFailed(let reason): return "Credential exchange failed: \(reason)"
        case .keychainError(let status): return "Keychain error: \(status)"
        case .invalidMessage: return "Received an invalid message from the gateway."
        }
    }

    public static func connectionFailed(_ reason: String) -> LocalApprovalError { .init(kind: .connectionFailed(reason)) }
    public static var approvalTimeout: LocalApprovalError { .init(kind: .approvalTimeout) }
    public static var approvalDenied: LocalApprovalError { .init(kind: .approvalDenied) }
    public static var permanentlyBlocked: LocalApprovalError { .init(kind: .permanentlyBlocked) }
    public static func exchangeFailed(_ reason: String) -> LocalApprovalError { .init(kind: .exchangeFailed(reason)) }
    public static func keychainError(_ status: Int32) -> LocalApprovalError { .init(kind: .keychainError(status)) }
    public static var invalidMessage: LocalApprovalError { .init(kind: .invalidMessage) }
}
