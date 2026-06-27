import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content.strip() + "\n")

# --- CORE LAYER ---
# M1
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Core/TLANModels.swift", """
import Foundation

/**
 TRUSTED LAN PAIRING — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       WebSocket over local TCP + Bonjour discovery
 Discovery:      NWBrowser scanning _openclaw._tcp Bonjour services
 Security:       HMAC-SHA256 challenge-response + 256-bit trust token
 Trust Store:    Keychain Services (Security.framework)
 Auto-Reconnect: Yes — token retrieved from Keychain, replayed on connect
 Frameworks:     Network.framework, Foundation, CryptoKit, Security.framework
 SPM Packages:   None

 HOW IT WORKS
 1. Gateway advertises _openclaw._tcp via NWListener TXT record
 2. iPhone browses with NWBrowser, user selects Mac from list
 3. iPhone opens URLSessionWebSocketTask to ws://[host]:[port]/alt/trusted-lan
 4. Gateway sends CHALLENGE: { nonce: base64(32 random bytes) }
 5. iPhone computes HMAC-SHA256(nonce, appInstallSecret) with CryptoKit
 6. iPhone sends CHALLENGE_RESPONSE: { hmac: base64(result) }
 7. Gateway validates HMAC (using stored per-device app secret)
 8. Gateway presents NSAlert on macOS main thread:
    "Dylan's iPhone 15 Pro wants to pair — Allow or Deny?"
 9. On Allow: Gateway generates 256-bit trust token via SecRandomCopyBytes
 10. Gateway stores device record: { deviceId, deviceName, trustToken, pairedAt }
 11. Gateway sends TRUST_TOKEN: { token, deviceId, expiresAt (30 days) }
 12. iPhone stores token in Keychain: service=com.toolskit.openclaw.trusted-lan
 13. iPhone sends ACK — pairing complete
 */

public struct TLANTrustToken: Codable, Equatable {
    public let token: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date
    public let pairedAt: Date

    public init(token: String, deviceId: String, gatewayId: String, expiresAt: Date, pairedAt: Date = Date()) {
        self.token = token
        self.deviceId = deviceId
        self.gatewayId = gatewayId
        self.expiresAt = expiresAt
        self.pairedAt = pairedAt
    }
}

public struct TLANDevice: Identifiable, Codable, Equatable {
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

public enum TLANPairingState: Equatable {
    case idle
    case discovering
    case discoveryFailed(String)
    case deviceSelected(String)
    case connecting
    case connectionFailed(String)
    case challengeReceived
    case challengeResponseSent
    case helloSent
    case awaitingApproval(Int)
    case approvalTimeout
    case approvalDenied
    case credentialExchange
    case exchangeFailed(String)
    case paired
    case ready
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
    public let expiresAt: Date?
    public let gatewayId: String?
    public let reason: String?

    public init(type: String, nonce: String? = nil, hmac: String? = nil, deviceId: String? = nil, deviceName: String? = nil, deviceModel: String? = nil, platform: String? = nil, appVersion: String? = nil, appInstallId: String? = nil, token: String? = nil, expiresAt: Date? = nil, gatewayId: String? = nil, reason: String? = nil) {
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
        self.expiresAt = expiresAt
        self.gatewayId = gatewayId
        self.reason = reason
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Core/TLANConstants.swift", """
import Foundation

public enum TLANConstants {
    public static let serviceType = "_openclaw._tcp"
    public static let defaultPort = 9876
    public static let connectionTimeout: TimeInterval = 30.0
    public static let approvalTimeout: TimeInterval = 120.0
    public static let keychainService = "com.toolskit.openclaw.trusted-lan"
    public static let appInstallSecretKey = "com.toolskit.openclaw.install-secret"
    public static let tokenRotationThreshold: TimeInterval = 7 * 24 * 60 * 60
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Core/TLANErrors.swift", """
import Foundation

public enum TLANError: Error, LocalizedError, Equatable {
    case discoveryFailed(String)
    case connectionFailed(String)
    case challengeTimeout
    case invalidChallenge
    case hmacComputationFailed
    case approvalDenied
    case approvalTimeout
    case exchangeFailed(String)
    case keychainError(Int32)
    case tokenExpired
    case invalidMessage

    public var errorDescription: String? {
        switch self {
        case .discoveryFailed(let reason): return "Discovery failed: \\(reason)"
        case .connectionFailed(let reason): return "Connection failed: \\(reason)"
        case .challengeTimeout: return "Gateway failed to send challenge in time."
        case .invalidChallenge: return "The received challenge was invalid."
        case .hmacComputationFailed: return "Failed to compute HMAC response."
        case .approvalDenied: return "Pairing request was denied on the Mac."
        case .approvalTimeout: return "Pairing request timed out."
        case .exchangeFailed(let reason): return "Credential exchange failed: \\(reason)"
        case .keychainError(let status): return "Keychain error: \\(status)"
        case .tokenExpired: return "Trust token has expired."
        case .invalidMessage: return "Received an invalid message from the gateway."
        }
    }
}
""")

# M2
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Core/PCModels.swift", """
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
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Core/PCConstants.swift", """
import Foundation

public enum PCConstants {
    public static let codeLength = 8
    public static let expiryWindow: TimeInterval = 60.0
    public static let validationEndpoint = "/alt/pairing-code/validate"
    public static let keychainService = "com.toolskit.openclaw.pairing-code"
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Core/PCErrors.swift", """
import Foundation

public enum PCError: Error, LocalizedError, Equatable {
    case codeInvalid
    case rateLimited(Int)
    case gatewayLocked
    case networkFailure(String)
    case exchangeFailed(String)
    case keychainError(Int32)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .codeInvalid: return "The pairing code is incorrect or has expired."
        case .rateLimited(let retryAfter): return "Too many attempts. Please try again in \\(retryAfter) seconds."
        case .gatewayLocked: return "Gateway is locked due to too many failed attempts. Restart the Gateway."
        case .networkFailure(let reason): return "Network error: \\(reason)"
        case .exchangeFailed(let reason): return "Credential exchange failed: \\(reason)"
        case .keychainError(let status): return "Keychain error: \\(status)"
        case .invalidResponse: return "The gateway returned an invalid response."
        }
    }
}
""")

# M3
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Core/QRModels.swift", """
import Foundation

/**
 QR CODE PAIRING — ARCHITECTURE
 ════════════════════════════════════════════════════════
 Protocol:       QR scan (AVFoundation) → HTTP POST validation → WebSocket
 QR Generation:  CoreImage CIFilter(\\"CIQRCodeGenerator\\") — no third-party library
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
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Core/QRConstants.swift", """
import Foundation

public enum QRConstants {
    public static let expiryDuration: TimeInterval = 60.0
    public static let validationEndpoint = "/alt/qr/validate"
    public static let keychainService = "com.toolskit.openclaw.qr-pairing"
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Core/QRErrors.swift", """
import Foundation

public enum QRError: Error, LocalizedError, Equatable {
    case filterUnavailable
    case generationFailed
    case cameraUnavailable
    case permissionDenied
    case scanTimeout
    case invalidPayload
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
        case .tokenExpired: return "The QR pairing token has expired."
        case .validationFailed(let reason): return "Validation failed: \\(reason)"
        case .keychainError(let status): return "Keychain error: \\(status)"
        }
    }
}
""")

# M4
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Core/MTModels.swift", """
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
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Core/MTConstants.swift", """
import Foundation

public enum MTConstants {
    public static let tokenLength = 44
    public static let expiryDuration: TimeInterval = 15 * 60
    public static let validationEndpoint = "/alt/manual-token/validate"
    public static let keychainService = "com.toolskit.openclaw.manual-token"
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Core/MTErrors.swift", """
import Foundation

public enum MTError: Error, LocalizedError, Equatable {
    case invalidFormat
    case networkError(String)
    case tokenInvalid
    case tokenExpired
    case keychainError(Int32)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat: return "The token format is invalid."
        case .networkError(let reason): return "Network error: \\(reason)"
        case .tokenInvalid: return "The pairing token is invalid."
        case .tokenExpired: return "The pairing token has expired."
        case .keychainError(let status): return "Keychain error: \\(status)"
        }
    }
}
""")

# M5
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Core/LAModels.swift", """
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
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Core/LAConstants.swift", """
import Foundation

public enum LAConstants {
    public static let defaultTimeout: TimeInterval = 120.0
    public static let keychainService = "com.toolskit.openclaw.local-approval"
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Core/LAErrors.swift", """
import Foundation

public enum LAError: Error, LocalizedError, Equatable {
    case connectionFailed(String)
    case approvalTimeout
    case approvalDenied
    case permanentlyBlocked
    case exchangeFailed(String)
    case keychainError(Int32)
    case invalidMessage

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason): return "Connection failed: \\(reason)"
        case .approvalTimeout: return "Approval timed out."
        case .approvalDenied: return "Approval request was denied."
        case .permanentlyBlocked: return "This device has been permanently blocked by the Mac."
        case .exchangeFailed(let reason): return "Credential exchange failed: \\(reason)"
        case .keychainError(let status): return "Keychain error: \\(status)"
        case .invalidMessage: return "Received an invalid message from the gateway."
        }
    }
}
""")

# --- SERVICES ---
# TLAN
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANTokenService.swift", """
import Foundation
import Security

public actor TLANTokenService {
    public static let shared = TLANTokenService()
    private init() {}

    public func saveToken(_ token: TLANTrustToken) throws {
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: TLANConstants.keychainService,
            kSecAttrAccount as String: token.gatewayId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw TLANError.keychainError(status) }
    }

    public func getToken(for gatewayId: String) throws -> TLANTrustToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: TLANConstants.keychainService,
            kSecAttrAccount as String: gatewayId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return try JSONDecoder().decode(TLANTrustToken.self, from: data)
        }
        return nil
    }

    public func deleteToken(for gatewayId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: TLANConstants.keychainService,
            kSecAttrAccount as String: gatewayId
        ]
        SecItemDelete(query as CFDictionary)
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANSecurityService.swift", """
import Foundation
import CryptoKit
import Security

public actor TLANSecurityService {
    public static let shared = TLANSecurityService()
    private init() {}

    public func getAppInstallSecret() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: TLANConstants.keychainService,
            kSecAttrAccount as String: TLANConstants.appInstallSecretKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return SymmetricKey(data: data)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: TLANConstants.keychainService,
                kSecAttrAccount as String: TLANConstants.appInstallSecretKey,
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
            return newKey
        }
    }

    public func computeHMAC(for nonce: Data) throws -> Data {
        let secret = try getAppInstallSecret()
        let hmac = HMAC<SHA256>.authenticationCode(for: nonce, using: secret)
        return Data(hmac)
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANValidationService.swift", """
import Foundation

public actor TLANValidationService {
    public static let shared = TLANValidationService()
    private init() {}

    public func validateMessage(_ data: Data) throws -> TLANMessage {
        let message = try JSONDecoder().decode(TLANMessage.self, from: data)
        if message.type.isEmpty { throw TLANError.invalidMessage }
        return message
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANDeviceManagerService.swift", """
import Foundation
import Observation

@Observable
public final class TLANDeviceManagerService {
    public static let shared = TLANDeviceManagerService()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "com.toolskit.openclaw.trusted-lan.devices"
    public private(set) var trustedDevices: [TLANDevice] = []
    private init() { loadDevices() }
    public func addDevice(_ device: TLANDevice) {
        if let index = trustedDevices.firstIndex(where: { $0.id == device.id }) { trustedDevices[index] = device }
        else { trustedDevices.append(device) }
        saveDevices()
    }
    public func removeDevice(id: String) { trustedDevices.removeAll(where: { $0.id == id }); saveDevices() }
    private func loadDevices() {
        if let data = userDefaults.data(forKey: storageKey), let devices = try? JSONDecoder().decode([TLANDevice].self, from: data) { self.trustedDevices = devices }
    }
    private func saveDevices() {
        if let data = try? JSONEncoder().encode(trustedDevices) { userDefaults.set(data, forKey: storageKey) }
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANSettingsService.swift", """
import Foundation
import Observation

@Observable
public final class TLANSettingsService {
    public static let shared = TLANSettingsService()
    private let userDefaults = UserDefaults.standard
    public var connectionTimeout: TimeInterval {
        get { userDefaults.double(forKey: "tlan_connection_timeout") == 0 ? 30.0 : userDefaults.double(forKey: "tlan_connection_timeout") }
        set { userDefaults.set(newValue, forKey: "tlan_connection_timeout") }
    }
    public var approvalTimeout: TimeInterval {
        get { userDefaults.double(forKey: "tlan_approval_timeout") == 0 ? 120.0 : userDefaults.double(forKey: "tlan_approval_timeout") }
        set { userDefaults.set(newValue, forKey: "tlan_approval_timeout") }
    }
    public var retryCount: Int {
        get { userDefaults.integer(forKey: "tlan_retry_count") == 0 ? 3 : userDefaults.integer(forKey: "tlan_retry_count") }
        set { userDefaults.set(newValue, forKey: "tlan_retry_count") }
    }
    private init() {}
}
""")

# PC Services
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Services/PCCodeValidationService.swift", """
import Foundation

public actor PCCodeValidationService {
    public static let shared = PCCodeValidationService()
    private init() {}
    public func validateCode(_ request: PCValidationRequest, gatewayHost: String, gatewayPort: Int) async throws -> PCValidationResponse {
        let url = URL(string: "http://\\(gatewayHost):\\(gatewayPort)\\(PCConstants.validationEndpoint)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else { throw PCError.networkFailure("Invalid response") }
        switch httpResponse.statusCode {
        case 200: return try JSONDecoder().decode(PCValidationResponse.self, from: data)
        case 401: throw PCError.codeInvalid
        case 429: throw PCError.rateLimited(60)
        case 423: throw PCError.gatewayLocked
        default: throw PCError.networkFailure("HTTP \\(httpResponse.statusCode)")
        }
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Services/PCTokenService.swift", """
import Foundation
import Security

public actor PCTokenService {
    public static let shared = PCTokenService()
    private init() {}
    public func saveToken(_ token: PCTrustToken) throws {
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: PCConstants.keychainService,
            kSecAttrAccount as String: token.gatewayId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw PCError.keychainError(status) }
    }
    public func getToken(for gatewayId: String) throws -> PCTrustToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: PCConstants.keychainService,
            kSecAttrAccount as String: gatewayId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return try JSONDecoder().decode(PCTrustToken.self, from: data) }
        return nil
    }
    public func deleteToken(for gatewayId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: PCConstants.keychainService,
            kSecAttrAccount as String: gatewayId
        ]
        SecItemDelete(query as CFDictionary)
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Services/PCSecurityService.swift", """
import Foundation
import Observation

@Observable
public final class PCSecurityService {
    public static let shared = PCSecurityService()
    public private(set) var lockoutEnd: Date?
    private init() {}
    public func setLockout(duration: TimeInterval) { lockoutEnd = Date().addingTimeInterval(duration) }
    public var isLocked: Bool {
        guard let end = lockoutEnd else { return false }
        return end > Date()
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Services/PCSettingsService.swift", """
import Foundation
import Observation

@Observable
public final class PCSettingsService {
    public static let shared = PCSettingsService()
    private let userDefaults = UserDefaults.standard
    public var gatewayURL: String {
        get { userDefaults.string(forKey: "pc_gateway_url") ?? "" }
        set { userDefaults.set(newValue, forKey: "pc_gateway_url") }
    }
    public var attemptLimit: Int {
        get { userDefaults.integer(forKey: "pc_attempt_limit") == 0 ? 10 : userDefaults.integer(forKey: "pc_attempt_limit") }
        set { userDefaults.set(newValue, forKey: "pc_attempt_limit") }
    }
    private init() {}
}
""")

# Hub
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/OpenClawAltViewModel.swift", """
import Foundation
import Observation

public enum ALTSecurityLevel: String { case medium, high, veryHigh }
public enum ALTReliabilityLevel: String { case high, veryHigh }
public enum ALTDifficultyLevel: String { case easy, medium, hard }
public enum ALTPairingStatus: String { case notPaired, pairing, paired, failed }
public enum ALTConnectionStatus: String { case disconnected, connecting, connected, error }

public struct OpenClawAltMethodCard: Identifiable {
    public let id: String
    public let name: String
    public let tagline: String
    public let description: String
    public let securityLevel: ALTSecurityLevel
    public let reliability: ALTReliabilityLevel
    public let difficulty: ALTDifficultyLevel
    public let estimatedSetupTime: String
    public let supportsAutoReconnect: Bool
    public let requiresCamera: Bool
    public let requiresManualCodeEntry: Bool
    public let isRecommended: Bool
    public var pairingStatus: ALTPairingStatus
    public var connectionStatus: ALTConnectionStatus
}

@Observable @MainActor
public final class OpenClawAltViewModel {
    public var methodCards: [OpenClawAltMethodCard] = [
        OpenClawAltMethodCard(id: "tlan", name: "Trusted LAN Pairing", tagline: "Strong verification via local network.", description: "Automatically find your Mac and request permission. High security, easy use.", securityLevel: .veryHigh, reliability: .veryHigh, difficulty: .easy, estimatedSetupTime: "~1 min", supportsAutoReconnect: true, requiresCamera: false, requiresManualCodeEntry: false, isRecommended: true, pairingStatus: .notPaired, connectionStatus: .disconnected),
        OpenClawAltMethodCard(id: "pc", name: "Pairing Code", tagline: "Type a short code from your Mac.", description: "Simplest for non-technical users. Just type 8 digits.", securityLevel: .high, reliability: .high, difficulty: .easy, estimatedSetupTime: "~30 sec", supportsAutoReconnect: true, requiresCamera: false, requiresManualCodeEntry: true, isRecommended: false, pairingStatus: .notPaired, connectionStatus: .disconnected),
        OpenClawAltMethodCard(id: "qr", name: "QR Code Pairing", tagline: "Scan to pair instantly.", description: "Point your camera at your Mac screen. Fastest setup.", securityLevel: .high, reliability: .high, difficulty: .easy, estimatedSetupTime: "~15 sec", supportsAutoReconnect: true, requiresCamera: true, requiresManualCodeEntry: false, isRecommended: false, pairingStatus: .notPaired, connectionStatus: .disconnected),
        OpenClawAltMethodCard(id: "mt", name: "Manual Pairing Token", tagline: "Copy/Paste a secure token.", description: "For power users or when camera is unavailable.", securityLevel: .high, reliability: .veryHigh, difficulty: .medium, estimatedSetupTime: "~1 min", supportsAutoReconnect: true, requiresCamera: false, requiresManualCodeEntry: true, isRecommended: false, pairingStatus: .notPaired, connectionStatus: .disconnected),
        OpenClawAltMethodCard(id: "la", name: "Local Approval", tagline: "One-click approval on Mac.", description: "Home users\\' favorite. No codes, no scanning.", securityLevel: .medium, reliability: .veryHigh, difficulty: .easy, estimatedSetupTime: "~30 sec", supportsAutoReconnect: true, requiresCamera: false, requiresManualCodeEntry: false, isRecommended: false, pairingStatus: .notPaired, connectionStatus: .disconnected)
    ]
    public init() {}
}
""")
