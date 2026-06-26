import Foundation

enum OpenClawError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case invalidResponse
    case requestTimeout
    case protocolError(String)
    case discoveryFailed(String)
    case deviceNotAuthorized
    case streamingError(String)
    case unreachableHost
    case invalidNonce
    case handshakeFailed(String)
    case connectionTimeout
    case invalidAuthMethodReuse
    case challengeResponseRejected(String)
    case missingChallengeNonce
    case socketClosedDuringAuth
    case protocolMismatchDetected(String)
    case authTimeoutWithoutServerAck
    case pairingRequired
    case pairingDenied
    case unknown

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection Failed: \(msg)"
        case .authenticationFailed(let msg): return "Authentication Failed: \(msg)"
        case .invalidResponse: return "Invalid response from gateway"
        case .requestTimeout: return "The request timed out"
        case .protocolError(let msg): return "Protocol Error: \(msg)"
        case .discoveryFailed(let msg): return "Discovery Failed: \(msg)"
        case .deviceNotAuthorized: return "Device not authorized"
        case .streamingError(let msg): return "Streaming Error: \(msg)"
        case .unreachableHost: return "Host is unreachable"
        case .invalidNonce: return "Invalid nonce received during handshake"
        case .handshakeFailed(let msg): return "Handshake Failed: \(msg)"
        case .connectionTimeout: return "The connection timed out"
        case .invalidAuthMethodReuse: return "Protocol Error: Invalid reuse of 'connect' method for authentication"
        case .challengeResponseRejected(let msg): return "Authentication Rejected: \(msg)"
        case .missingChallengeNonce: return "Authentication Failed: Missing challenge nonce"
        case .socketClosedDuringAuth: return "Connection Lost: Socket closed during authentication"
        case .protocolMismatchDetected(let msg): return "Protocol Mismatch: \(msg)"
        case .authTimeoutWithoutServerAck: return "Authentication Timed Out: No response from gateway"
        case .pairingRequired: return "Pairing Required: Please approve on the host"
        case .pairingDenied: return "Pairing Denied: The request was rejected by the host"
        case .unknown: return "An unknown error occurred"
        }
    }
}
