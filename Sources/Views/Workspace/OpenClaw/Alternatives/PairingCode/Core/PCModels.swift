import Foundation

/**
 ONE-TIME PAIRING CODE — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       HTTP POST for code validation, WebSocket for subsequent connection
 Code Type:      TOTP-derived 8-digit numeric code (HMAC-SHA256 of timestamp)
 Security:       Constant-time comparison, rate limiting, brute-force lockout
 Trust Store:    Keychain Services (Security.framework)
 Auto-Reconnect: Yes — permanent trust token stored in Keychain after pairing
 Frameworks:     Foundation (URLSession), CryptoKit, Security.framework
 SPM Packages:   None
 */

public enum PCPairingState: Equatable {
    case idle
    case awaitingCodeInput
    case codeEntered(String)
    case submitting
    case codeInvalid
    case rateLimited(Int)
    case gatewayLocked
    case networkError(String)
    case credentialExchange
    case exchangeFailed(String)
    case paired
    case connected
    case ready
}

public struct PCTrustToken: Codable, Equatable {
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

public struct PCValidationRequest: Codable {
    public let code: String
    public let deviceName: String
    public let deviceModel: String
    public let platform: String
    public let appVersion: String
    public let appInstallId: String

    public init(code: String, deviceName: String, deviceModel: String, platform: String, appVersion: String, appInstallId: String) {
        self.code = code
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.platform = platform
        self.appVersion = appVersion
        self.appInstallId = appInstallId
    }
}

public struct PCValidationResponse: Codable {
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
