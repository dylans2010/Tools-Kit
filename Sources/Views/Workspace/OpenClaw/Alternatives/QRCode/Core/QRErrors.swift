import Foundation

public enum QRError: Error, LocalizedError, Equatable {
    case filterUnavailable
    case generationFailed
    case cameraUnavailable
    case permissionDenied
    case scanTimeout
    case invalidPayload
    case invalidFormat
    case tokenExpired
    case validationFailed(String)
    case keychainError(Int32)

    public var errorDescription: String? {
        switch self {
        case .filterUnavailable: return "QR filter is unavailable."
        case .generationFailed: return "Failed to generate QR image."
        case .cameraUnavailable: return "Camera is unavailable."
        case .permissionDenied: return "Camera permission was denied."
        case .scanTimeout: return "QR scan timed out."
        case .invalidPayload: return "The QR code contains an invalid payload."
        case .invalidFormat: return "The QR code has an invalid format."
        case .tokenExpired: return "The QR pairing token has expired."
        case .validationFailed(let reason): return "Validation failed: \(reason)"
        case .keychainError(let status): return "Keychain error: \(status)"
        }
    }
}
