import Foundation

/**
 QR CODE PAIRING — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       QR scan (AVFoundation) → HTTP POST validation → WebSocket
 QR Generation:  CoreImage CIFilter(\"CIQRCodeGenerator\") — no third-party library
 QR Scanning:    AVFoundation AVCaptureMetadataOutput — no third-party library
 Security:       Single-use one-time token embedded in QR, 60-second expiry
 Trust Store:    Keychain Services (Security.framework)
 Auto-Reconnect: Yes — permanent trust token stored in Keychain after pairing
 Frameworks:     CoreImage, AVFoundation, Foundation (URLSession), Security.framework
 SPM Packages:   None
 */

public struct QRPayload: Codable, Equatable {
    public let v: Int
    public let host: String
    public let port: Int
    public let token: String
    public let gatewayId: String
    public let expiresAt: Date
    public let method: String

    public init(v: Int, host: String, port: Int, token: String, gatewayId: String, expiresAt: Date, method: String = "qr") {
        self.v = v
        self.host = host
        self.port = port
        self.token = token
        self.gatewayId = gatewayId
        self.expiresAt = expiresAt
        self.method = method
    }
}

public enum QRPairingState: Equatable {
    case idle
    case checkingPermission
    case permissionDenied
    case scannerStarting
    case scanning
    case scanTimeout
    case scanComplete
    case parsingPayload
    case parseError(String)
    case payloadInvalid(String)
    case tokenExpired
    case validatingWithGateway
    case validationFailed(String)
    case tokenUsedOrExpired
    case credentialExchange
    case paired
    case ready
}

public struct QRScanResult: Equatable {
    public let payload: QRPayload
    public let rawString: String
}

public struct QRTrustToken: Codable, Equatable {
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
