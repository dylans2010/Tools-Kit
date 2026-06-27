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

import Foundation
import CryptoKit

public actor PCPairingEngine {
    private let client = PCHTTPClient()
    private let tokenService = PCTokenService.shared

    public init() {}

    public func submitCode(_ code: String, host: String, port: Int) async throws {
        let info = await LADeviceInfoService.shared.getDeviceInfo()
        let result = try await client.validate(code: code, host: host, port: port, deviceInfo: info)
        try await tokenService.saveToken(result)
    }
}
