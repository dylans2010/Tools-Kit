import Foundation

/**
 MANUAL PAIRING TOKEN — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       HTTP POST for token validation → WebSocket for connection
 Token Format:   32 bytes SecRandomCopyBytes → Base64 (44 chars) → grouped display
 Security:       Single-use, 15-minute expiry, Keychain trust storage
 Trust Store:    Keychain Services (Security.framework)
 Auto-Reconnect: Yes — permanent trust token stored in Keychain after pairing
 Frameworks:     Foundation (URLSession, UIPasteboard), Security.framework
 SPM Packages:   None
 */

public enum MTPairingState: Equatable {
    case idle
    case awaitingToken
    case tokenAutoFilled
    case tokenEntered
    case formatValidated
    case formatInvalid
    case submitting
    case networkError(String)
    case tokenInvalid(String)
    case tokenExpired
    case credentialExchange
    case paired
    case ready
}

public struct MTTrustToken: Codable, Equatable {
    public let token: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date

    public init(token: String, deviceId: String, gatewayId: String, expiresAt: Date) {
        self.token = token
        self.deviceId = deviceId
        self.gatewayId = gatewayId
        self.expiresAt = expiresAt
    }
}

public struct MTValidationResult: Codable {
    public let trustToken: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date

    public init(trustToken: String, deviceId: String, gatewayId: String, expiresAt: Date) {
        self.trustToken = trustToken
        self.deviceId = deviceId
        self.gatewayId = gatewayId
        self.expiresAt = expiresAt
    }
}
