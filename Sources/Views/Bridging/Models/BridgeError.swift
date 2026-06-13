import Foundation

public enum BridgeError: Error, Codable, Equatable, LocalizedError {
    case unreachableHost
    case timeout
    case invalidResponse
    case connectionRefused
    case invalidPairingCode
    case expiredSession
    case unauthorizedAccess
    case commandRejected(String)
    case unsafeCommandBlocked
    case runtimeFailure(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .unreachableHost: return "Host unreachable"
        case .timeout: return "Connection timeout"
        case .invalidResponse: return "Invalid response from host"
        case .connectionRefused: return "Connection refused"
        case .invalidPairingCode: return "Invalid pairing code"
        case .expiredSession: return "Session expired"
        case .unauthorizedAccess: return "Unauthorized access"
        case .commandRejected(let reason): return "Command rejected: \(reason)"
        case .unsafeCommandBlocked: return "Unsafe command blocked"
        case .runtimeFailure(let reason): return "Runtime failure: \(reason)"
        case .unknown(let message): return "Unknown error: \(message)"
        }
    }
}
