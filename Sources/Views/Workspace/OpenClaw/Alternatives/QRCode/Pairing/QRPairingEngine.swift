/**
QR CODE PAIRING — ARCHITECTURE
════════════════════════════════════════════════════════
Protocol:       QR scan (AVFoundation) → HTTP POST validation → WebSocket
QR Generation:  CoreImage CIFilter("CIQRCodeGenerator") — no third-party library
QR Scanning:    AVFoundation AVCaptureMetadataOutput — no third-party library
Security:       Single-use one-time token embedded in QR, 60-second expiry
Trust Store:    Keychain Services (Security.framework)
Auto-Reconnect: Yes — permanent trust token stored in Keychain after pairing
Frameworks:     CoreImage, AVFoundation, Foundation (URLSession), Security.framework
SPM Packages:   None
*/

import Foundation

public actor QRPairingEngine {
    private let validationService = QRValidationService.shared
    private let tokenService = QRTokenService.shared

    public init() {}

    public func processScanResult(_ payload: String) async throws {
        let parser = QRPayloadParserService()
        let decoded = try parser.parse(payload)
        let info = await LADeviceInfoService.shared.getDeviceInfo()
        let result = try await validationService.validate(payload: decoded, deviceInfo: info)
        try await tokenService.saveToken(result)
    }
}
