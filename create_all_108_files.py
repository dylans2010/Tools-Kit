import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content.strip() + "\n")

# Hub
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/OpenClawAltView.swift", """
import SwiftUI

public struct OpenClawAltView: View {
    @State private var viewModel = OpenClawAltViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.methodCards) { card in
                    methodCard(card)
                }
            }
            .padding()
        }
        .navigationTitle("Pairing Methods")
        .background(Color(.systemGroupedBackground))
    }

    private func methodCard(_ card: OpenClawAltMethodCard) -> some View {
        NavigationLink(destination: destinationView(for: card.id)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(card.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if card.isRecommended {
                        Text("Recommended")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                Text(card.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    securityBadge(card.securityLevel)
                    reliabilityBadge(card.reliability)
                    difficultyBadge(card.difficulty)
                }

                HStack(spacing: 12) {
                    Label(card.estimatedSetupTime, systemImage: "timer")
                    if card.supportsAutoReconnect {
                        Label("Auto-Reconnect", systemImage: "arrow.clockwise")
                    }
                    if card.requiresCamera {
                        Label("Camera", systemImage: "camera")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func securityBadge(_ level: ALTSecurityLevel) -> some View {
        Label(level.rawValue.capitalized, systemImage: "lock.shield")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(levelColor(level).opacity(0.1))
            .foregroundStyle(levelColor(level))
            .clipShape(Capsule())
    }

    private func levelColor(_ level: ALTSecurityLevel) -> Color {
        switch level {
        case .veryHigh: return .green
        case .high: return .teal
        case .medium: return .orange
        }
    }

    private func reliabilityBadge(_ level: ALTReliabilityLevel) -> some View {
        Label("Reliable", systemImage: "antenna.radiowaves.left.and.right")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }

    private func difficultyBadge(_ level: ALTDifficultyLevel) -> some View {
        Label(level.rawValue.capitalized, systemImage: "hammer")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func destinationView(for id: String) -> some View {
        switch id {
        case "tlan": TLANHomeView()
        case "pc": PCHomeView()
        case "qr": QRHomeView()
        case "mt": MTHomeView()
        case "la": LAHomeView()
        default: Text("Unknown Method")
        }
    }
}
""")

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
        OpenClawAltMethodCard(id: "la", name: "Local Approval", tagline: "One-click approval on Mac.", description: "Home users' favorite. No codes, no scanning.", securityLevel: .medium, reliability: .veryHigh, difficulty: .easy, estimatedSetupTime: "~30 sec", supportsAutoReconnect: true, requiresCamera: false, requiresManualCodeEntry: false, isRecommended: false, pairingStatus: .notPaired, connectionStatus: .disconnected)
    ]
    public init() {}
}
""")

# M1 - TrustedLAN
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
 */

public struct TLANTrustToken: Codable, Equatable {
    public let token: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date
    public let pairedAt: Date
    public init(token: String, deviceId: String, gatewayId: String, expiresAt: Date, pairedAt: Date = Date()) {
        self.token = token; self.deviceId = deviceId; self.gatewayId = gatewayId; self.expiresAt = expiresAt; self.pairedAt = pairedAt
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
        self.id = id; self.name = name; self.model = model; self.platform = platform; self.appVersion = appVersion; self.appInstallId = appInstallId; self.pairedAt = pairedAt
    }
}

public enum TLANPairingState: Equatable {
    case idle, discovering, discoveryFailed(String), deviceSelected(String), connecting, connectionFailed(String), challengeReceived, challengeResponseSent, helloSent, awaitingApproval(Int), approvalTimeout, approvalDenied, credentialExchange, exchangeFailed(String), paired, ready
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
        self.type = type; self.nonce = nonce; self.hmac = hmac; self.deviceId = deviceId; self.deviceName = deviceName; self.deviceModel = deviceModel; self.platform = platform; self.appVersion = appVersion; self.appInstallId = appInstallId; self.token = token; self.expiresAt = expiresAt; self.gatewayId = gatewayId; self.reason = reason
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
    case discoveryFailed(String), connectionFailed(String), challengeTimeout, invalidChallenge, hmacComputationFailed, approvalDenied, approvalTimeout, exchangeFailed(String), keychainError(Int32), tokenExpired, invalidMessage
    public var errorDescription: String? {
        switch self {
        case .discoveryFailed(let r): return "Discovery failed: \\(r)"
        case .connectionFailed(let r): return "Connection failed: \\(r)"
        case .challengeTimeout: return "Challenge timeout"
        case .invalidChallenge: return "Invalid challenge"
        case .hmacComputationFailed: return "HMAC failed"
        case .approvalDenied: return "Approval denied"
        case .approvalTimeout: return "Approval timeout"
        case .exchangeFailed(let r): return "Exchange failed: \\(r)"
        case .keychainError(let s): return "Keychain error: \\(s)"
        case .tokenExpired: return "Token expired"
        case .invalidMessage: return "Invalid message"
        }
    }
}
""")

# M1 Services
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANTokenService.swift", """
import Foundation
import Security
public actor TLANTokenService {
    public static let shared = TLANTokenService()
    private init() {}
    public func saveToken(_ token: TLANTrustToken) throws {
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: token.gatewayId, kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw TLANError.keychainError(status) }
    }
    public func getToken(for gatewayId: String) throws -> TLANTrustToken? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: gatewayId, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?; let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return try JSONDecoder().decode(TLANTrustToken.self, from: data) }
        return nil
    }
    public func deleteToken(for gatewayId: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: gatewayId]
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
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: TLANConstants.appInstallSecretKey, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?; let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return SymmetricKey(data: data) }
        let newKey = SymmetricKey(size: .bits256); let keyData = newKey.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: TLANConstants.keychainService, kSecAttrAccount as String: TLANConstants.appInstallSecretKey, kSecValueData as String: keyData, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        SecItemAdd(addQuery as CFDictionary, nil); return newKey
    }
    public func computeHMAC(for nonce: Data) throws -> Data {
        let secret = try getAppInstallSecret(); let hmac = HMAC<SHA256>.authenticationCode(for: nonce, using: secret); return Data(hmac)
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
@Observable public final class TLANDeviceManagerService {
    public static let shared = TLANDeviceManagerService()
    private let userDefaults = UserDefaults.standard; private let storageKey = "com.toolskit.openclaw.trusted-lan.devices"
    public private(set) var trustedDevices: [TLANDevice] = []
    private init() { loadDevices() }
    public func addDevice(_ device: TLANDevice) {
        if let index = trustedDevices.firstIndex(where: { $0.id == device.id }) { trustedDevices[index] = device }
        else { trustedDevices.append(device) }; saveDevices()
    }
    public func removeDevice(id: String) { trustedDevices.removeAll(where: { $0.id == id }); saveDevices() }
    private func loadDevices() {
        if let data = userDefaults.data(forKey: storageKey), let devices = try? JSONDecoder().decode([TLANDevice].self, from: data) { self.trustedDevices = devices }
    }
    private func saveDevices() { if let data = try? JSONEncoder().encode(trustedDevices) { userDefaults.set(data, forKey: storageKey) } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Services/TLANSettingsService.swift", """
import Foundation
import Observation
@Observable public final class TLANSettingsService {
    public static let shared = TLANSettingsService()
    private let userDefaults = UserDefaults.standard
    public var connectionTimeout: TimeInterval { get { userDefaults.double(forKey: "t_timeout") == 0 ? 30 : userDefaults.double(forKey: "t_timeout") } set { userDefaults.set(newValue, forKey: "t_timeout") } }
    public var approvalTimeout: TimeInterval { get { userDefaults.double(forKey: "a_timeout") == 0 ? 120 : userDefaults.double(forKey: "a_timeout") } set { userDefaults.set(newValue, forKey: "a_timeout") } }
    public var retryCount: Int { get { userDefaults.integer(forKey: "r_count") == 0 ? 3 : userDefaults.integer(forKey: "r_count") } set { userDefaults.set(newValue, forKey: "r_count") } }
    private init() {}
}
""")

# M1 Connections
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Connections/TLANWebSocketConnection.swift", """
import Foundation
import OSLog
public actor TLANWebSocketConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL; private var socket: URLSessionWebSocketTask?; private var session: URLSession?; private var isSocketOpen = false
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "trusted-lan-ws")
    private var eventContinuation: AsyncStream<Data>.Continuation?
    public init(url: URL) {
        self.url = url; super.init(); let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    public func connect() -> AsyncStream<Data> {
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self); self.eventContinuation = continuation
        socket = session?.webSocketTask(with: url); socket?.resume(); listen(); return stream
    }
    public func disconnect() { socket?.cancel(with: .normalClosure, reason: nil); isSocketOpen = false; eventContinuation?.finish() }
    public func send(data: Data) async throws {
        guard let socket = socket, isSocketOpen else { throw TLANError.connectionFailed("Socket not open") }
        try await socket.send(.data(data))
    }
    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            Task {
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data): await self.eventContinuation?.yield(data)
                    case .string(let text): if let data = text.data(using: .utf8) { await self.eventContinuation?.yield(data) }
                    @unknown default: break
                    }
                    await self.listen()
                case .failure(let error): self.logger.error("WS Error: \\(error.localizedDescription)"); await self.markClosed()
                }
            }
        }
    }
    private func markOpen() { isSocketOpen = true }
    private func markClosed() { isSocketOpen = false; eventContinuation?.finish() }
    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol p: String?) { Task { await self.markOpen() } }
    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith c: URLSessionWebSocketTask.CloseCode, reason r: Data?) { Task { await self.markClosed() } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Connections/TLANBonjourBrowser.swift", """
import Foundation
import Network
public actor TLANBonjourBrowser {
    public static let shared = TLANBonjourBrowser(); private var browser: NWBrowser?; private var resultsContinuation: AsyncStream<[NWBrowser.Result]>.Continuation?
    private init() {}
    public func startBrowsing() -> AsyncStream<[NWBrowser.Result]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NWBrowser.Result].self); self.resultsContinuation = continuation
        let p = NWParameters(); p.includePeerToPeer = true
        let b = NWBrowser(for: .bonjour(type: TLANConstants.serviceType, domain: nil), using: p); self.browser = b
        b.browseResultsChangedHandler = { [weak self] r, c in Task { await self?.resultsContinuation?.yield(Array(r)) } }
        b.start(queue: .global(qos: .userInitiated)); return stream
    }
    public func stopBrowsing() { browser?.cancel(); browser = nil; resultsContinuation?.finish() }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Connections/TLANSessionManager.swift", """
import Foundation
import Observation
public actor TLANSessionManager {
    public static let shared = TLANSessionManager(); private var connection: TLANWebSocketConnection?
    private init() {}
    public func establishSession(url: URL) async throws {
        let c = TLANWebSocketConnection(url: url); self.connection = c; let stream = await c.connect()
        Task { for await data in stream { OpenClawLoggerService.shared.log(level: .debug, category: .websocket, title: "TLAN Data", description: "Bytes: \\(data.count)") } }
    }
    public func disconnect() async { await connection?.disconnect(); connection = nil }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Connections/TLANHTTPClient.swift", """
import Foundation
public actor TLANHTTPClient {
    public static let shared = TLANHTTPClient(); private init() {}
    public func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) { return try await URLSession.shared.data(for: request) }
}
""")

# M1 Pairing
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Pairing/TLANPairingEngine.swift", """
import Foundation
import OSLog
import CryptoKit
public actor TLANPairingEngine {
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "trusted-lan-engine")
    private var connection: TLANWebSocketConnection?; private let tokenService = TLANTokenService.shared; private let securityService = TLANSecurityService.shared
    public init() {}
    public func startPairing(url: URL) async throws {
        let c = TLANWebSocketConnection(url: url); self.connection = c; let stream = await c.connect()
        for await data in stream { try await handleMessage(data) }
    }
    private func handleMessage(_ data: Data) async throws {
        let m = try JSONDecoder().decode(TLANMessage.self, from: data)
        switch m.type {
        case "CHALLENGE":
            guard let nStr = m.nonce, let nData = Data(base64Encoded: nStr) else { throw TLANError.invalidChallenge }
            let h = try await securityService.computeHMAC(for: nData); try await send(TLANMessage(type: "CHALLENGE_RESPONSE", hmac: h.base64EncodedString()))
            let info = await LADeviceInfoService.shared.getDeviceInfo()
            try await send(TLANMessage(type: "HELLO", deviceId: info.appInstallId, deviceName: info.deviceName, deviceModel: info.deviceModel, platform: info.platform, appVersion: info.appVersion, appInstallId: info.appInstallId))
        case "TRUST_TOKEN":
            guard let t = m.token, let di = m.deviceId, let gi = m.gatewayId, let ex = m.expiresAt else { throw TLANError.invalidMessage }
            try await tokenService.saveToken(TLANTrustToken(token: t, deviceId: di, gatewayId: gi, expiresAt: ex)); try await send(TLANMessage(type: "ACK"))
        case "APPROVAL_DENIED": throw TLANError.approvalDenied
        default: logger.warning("Unknown message type: \\(m.type)")
        }
    }
    private func send(_ m: TLANMessage) async throws { let d = try JSONEncoder().encode(m); try await connection?.send(data: d) }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Pairing/TLANTrustManager.swift", """
import Foundation
public actor TLANTrustManager {
    public static let shared = TLANTrustManager(); private let tokenService = TLANTokenService.shared; private init() {}
    public func checkTrust(for gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) { return token.expiresAt > Date() }; return false
    }
    public func revokeTrust(for gatewayId: String) async { await tokenService.deleteToken(for: gatewayId) }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Pairing/TLANCredentialExchange.swift", """
import Foundation
public actor TLANCredentialExchange {
    public static let shared = TLANCredentialExchange(); private init() {}
    public func exchangeToken(_ token: TLANTrustToken) async throws {}
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Pairing/TLANValidationEngine.swift", """
import Foundation
public actor TLANValidationEngine {
    public static let shared = TLANValidationEngine(); private init() {}
    public func validateResponse(_ m: TLANMessage) throws -> Bool { return m.type != "ERROR" }
}
""")

# M1 ViewModels
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/ViewModels/TLANPairingViewModel.swift", """
import Foundation
import Observation
import OSLog
@Observable @MainActor public final class TLANPairingViewModel {
    public var state: TLANPairingState = .idle; public var lastError: String?
    private let pairingEngine = TLANPairingEngine()
    public init() {}
    public func pair(with result: Network.NWBrowser.Result) async { state = .connecting }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/ViewModels/TLANDiscoveryViewModel.swift", """
import Foundation
import Observation
import Network
@Observable @MainActor public final class TLANDiscoveryViewModel {
    public var results: [NWBrowser.Result] = []; public var isScanning = false
    public init() {}
    public func startDiscovery() async {
        isScanning = true; let stream = await TLANBonjourBrowser.shared.startBrowsing()
        for await newResults in stream { self.results = newResults }
    }
    public func stopDiscovery() async { await TLANBonjourBrowser.shared.stopBrowsing(); isScanning = false }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/ViewModels/TLANStatusViewModel.swift", """
import Foundation
import Observation
@Observable @MainActor public final class TLANStatusViewModel {
    public var isConnected = false; public var pairedDeviceName: String?; public init() {}
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/ViewModels/TLANDeviceListViewModel.swift", """
import Foundation
import Observation
@Observable @MainActor public final class TLANDeviceListViewModel {
    public var devices: [TLANDevice] { TLANDeviceManagerService.shared.trustedDevices }; public init() {}
    public func removeDevice(id: String) { TLANDeviceManagerService.shared.removeDevice(id: id) }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/ViewModels/TLANDiagnosticsViewModel.swift", """
import Foundation
import Observation
@Observable @MainActor public final class TLANDiagnosticsViewModel {
    public var logs: [String] = []; public init() {}
    public func exportLogs() {}
}
""")

# M1 Views
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANHomeView.swift", """
import SwiftUI
public struct TLANHomeView: View {
    @State private var discoveryVM = TLANDiscoveryViewModel()
    public init() {}
    public var body: some View {
        List {
            Section("Method") { Text("Trusted LAN Pairing").font(.headline); Text("Automatically find your Mac and request permission to connect.").font(.subheadline).foregroundStyle(.secondary) }
            Section("Status") { HStack { Text("Paired Status"); Spacer(); Text("Not Paired").foregroundStyle(.secondary) } }
            Section { NavigationLink("Start Discovery") { TLANDiscoveryView(viewModel: discoveryVM) } }
            Section { NavigationLink("User Guide") { TLANGuideView() } }
        }.navigationTitle("Trusted LAN")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANDiscoveryView.swift", """
import SwiftUI
import Network
public struct TLANDiscoveryView: View {
    @Bindable var viewModel: TLANDiscoveryViewModel
    public var body: some View {
        List {
            if viewModel.results.isEmpty { Section { HStack { ProgressView(); Text("Searching for Gateways...").padding(.leading, 8) } } }
            else { Section("Discovered Devices") { ForEach(viewModel.results, id: \\.self) { r in
                NavigationLink(destination: TLANPairingView(result: r)) { VStack(alignment: .leading) { Text(r.endpoint.debugDescription).font(.headline); Text("Select to request pairing").font(.caption).foregroundStyle(.secondary) } }
            } } }
        }.navigationTitle("Discovery").task { await viewModel.startDiscovery() }.onDisappear { Task { await viewModel.stopDiscovery() } }
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANPairingView.swift", """
import SwiftUI
import Network
public struct TLANPairingView: View {
    let result: NWBrowser.Result; @State private var viewModel = TLANPairingViewModel()
    public var body: some View {
        VStack(spacing: 20) { ProgressView().controlSize(.large); Text("Requesting Approval...").font(.title2); Text("Please check your Mac for an approval dialog.").foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let e = viewModel.lastError { Text(e).foregroundStyle(.red).font(.caption) }
        }.padding().navigationTitle("Pairing")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANStatusView.swift", """
import SwiftUI
public struct TLANStatusView: View {
    @State private var viewModel = TLANStatusViewModel()
    public var body: some View { List { Section("Connection") { HStack { Text("Status"); Spacer(); Text(viewModel.isConnected ? "Connected" : "Disconnected").foregroundStyle(viewModel.isConnected ? .green : .secondary) } } }.navigationTitle("TLAN Status") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANDeviceListView.swift", """
import SwiftUI
public struct TLANDeviceListView: View {
    @State private var viewModel = TLANDeviceListViewModel()
    public var body: some View {
        List { Section("Trusted Devices") { if viewModel.devices.isEmpty { Text("No trusted devices").foregroundStyle(.secondary) }
            else { ForEach(viewModel.devices) { d in VStack(alignment: .leading) { Text(d.name).font(.headline); Text("Paired at: \\(d.pairedAt.formatted())").font(.caption) } } } }
        }.navigationTitle("Devices")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANDiagnosticsView.swift", """
import SwiftUI
public struct TLANDiagnosticsView: View {
    @State private var viewModel = TLANDiagnosticsViewModel(); @Environment(\\.dismiss) private var dismiss
    public var body: some View {
        List { Section("Status") { LabeledContent("Pairing State", value: "\\(TLANPairingState.idle)"); LabeledContent("Connection", value: "Disconnected"); LabeledContent("Gateway Address", value: "--"); LabeledContent("Protocol Ver.", value: "v1") }
            Section { Button("Export Diagnostics") { viewModel.exportLogs() }; Button("Reset & Unpair", role: .destructive) {} }
        }.navigationTitle("TLAN Diagnostics")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANSettingsView.swift", """
import SwiftUI
public struct TLANSettingsView: View {
    @State private var settings = TLANSettingsService.shared
    public var body: some View {
        Form { Section("Connection") { TextField("Gateway Host", text: .constant("")); Stepper("Timeout: \\(Int(settings.connectionTimeout))s", value: $settings.connectionTimeout, in: 5...120) }
            Section("Trust") { Button("Forget Device", role: .destructive) {} }
        }.navigationTitle("TLAN Settings")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/TrustedLAN/Views/TLANGuideView.swift", """
import SwiftUI
public struct TLANGuideView: View {
    public var body: some View {
        List {
            Section("What Is This?") { Text("Trusted LAN Pairing uses your local Wi-Fi network to automatically find your Mac and request permission to connect.") }
            Section("Best For") { Text("• Offices, shared networks, or any situation where you want the strongest verification before granting access.") }
            Section("Step-by-Step") { VStack(alignment: .leading, spacing: 10) { Text("On Your iPhone:").bold(); Text("1. Tap 'Trusted LAN Pairing'\\n2. Wait for your Mac\\n3. Tap your Mac's name\\n4. Wait for approval on Mac") } }
        }.navigationTitle("Trusted LAN Guide")
    }
}
""")
