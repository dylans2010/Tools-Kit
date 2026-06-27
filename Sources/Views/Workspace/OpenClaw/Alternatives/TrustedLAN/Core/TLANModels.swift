
import Foundation

public enum TLANPairingState: Equatable {
    case idle, discovering, connecting, challengeReceived, awaitingApproval(countdown: Int), paired, failed(String)
}

public struct TLANDevice: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let pairedAt: Date

    public init(id: String, name: String, pairedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.pairedAt = pairedAt
    }
}

public struct TLANTrustToken: Codable {
    public let token: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date
}

public struct TLANMessage: Codable {
    public let type: String
    public let nonce: String?
    public let hmac: String?
    public let deviceId: String?
    public let deviceName: String?
    public let deviceModel: String?
    public let platform: String?
    public let appVersion: String?
    public let appInstallId: String?
    public let token: String?
    public let gatewayId: String?
    public let expiresAt: Date?

    public init(type: String, nonce: String? = nil, hmac: String? = nil, deviceId: String? = nil, deviceName: String? = nil, deviceModel: String? = nil, platform: String? = nil, appVersion: String? = nil, appInstallId: String? = nil, token: String? = nil, gatewayId: String? = nil, expiresAt: Date? = nil) {
        self.type = type
        self.nonce = nonce
        self.hmac = hmac
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.platform = platform
        self.appVersion = appVersion
        self.appInstallId = appInstallId
        self.token = token
        self.gatewayId = gatewayId
        self.expiresAt = expiresAt
    }
}
