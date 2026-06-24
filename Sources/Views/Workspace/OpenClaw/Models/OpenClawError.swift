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
        case .unknown: return "An unknown error occurred"
        }
    }
}
