import Foundation

/**
 LOCAL APPROVAL PAIRING — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       WebSocket connection → HELLO → Mac approval dialog → TRUST_TOKEN
 Discovery:      NWBrowser (optional) or manual IP:port
 Security:       Trust token (256-bit) + device record — no challenge-response phase
 Trust Store:    Keychain Services (Security.framework)
 Auto-Reconnect: Yes — permanent trust token stored in Keychain after approval
 Frameworks:     Network.framework, Foundation, UIKit (UIDevice), AppKit (NSAlert)
 SPM Packages:   None
 */

public enum LAPairingState: Equatable {
    case idle
    case selecting
    case connecting
    case connectionFailed(String)
    case helloSent
    case awaitingApproval(Int)
    case approvalTimeout
    case approvalDenied
    case permanentlyBlocked
    case credentialExchange
    case exchangeFailed(String)
    case paired
    case ready
}

public struct LADevice: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public let model: String
    public let platform: String
    public let appVersion: String
    public let appInstallId: String
    public var pairedAt: Date

    public init(id: String, name: String, model: String, platform: String, appVersion: String, appInstallId: String, pairedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.model = model
        self.platform = platform
        self.appVersion = appVersion
        self.appInstallId = appInstallId
        self.pairedAt = pairedAt
    }
}

public struct LATrustToken: Codable, Equatable {
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

public struct LADeviceInfo: Codable, Equatable {
    public let deviceName: String
    public let deviceModel: String
    public let platform: String
    public let iOSVersion: String
    public let appVersion: String
    public let appInstallId: String
    public let localIP: String

    public init(deviceName: String, deviceModel: String, platform: String, iOSVersion: String, appVersion: String, appInstallId: String, localIP: String) {
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.platform = platform
        self.iOSVersion = iOSVersion
        self.appVersion = appVersion
        self.appInstallId = appInstallId
        self.localIP = localIP
    }
}
