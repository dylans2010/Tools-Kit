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

import Foundation

public actor MTPairingEngine {
    private let validationService = MTValidationService.shared
    private let tokenService = MTTokenService.shared

    public init() {}

    public func validateToken(_ token: String, host: String, port: Int) async throws {
        let info = await LADeviceInfoService.shared.getDeviceInfo()
        let result = try await validationService.validate(token: token, host: host, port: port, deviceInfo: info)
        try await tokenService.saveToken(result)
    }
}
