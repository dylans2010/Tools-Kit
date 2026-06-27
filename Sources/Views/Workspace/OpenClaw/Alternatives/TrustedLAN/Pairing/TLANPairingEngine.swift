
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

import Foundation
import OSLog
import CryptoKit

public actor TLANPairingEngine {
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "trusted-lan-engine")
    private var connection: TLANWebSocketConnection?
    private let tokenService = TLANTokenService.shared
    private let securityService = TLANSecurityService.shared

    public init() {}

    public func startPairing(url: URL) async throws -> AsyncStream<TLANPairingState> {
        let (stream, continuation) = AsyncStream.makeStream(of: TLANPairingState.self)

        let c = TLANWebSocketConnection(url: url)
        self.connection = c
        continuation.yield(.connecting)

        let dataStream = await c.connect()

        Task {
            do {
                for await data in dataStream {
                    try await handleMessage(data, continuation: continuation)
                }
            } catch {
                continuation.yield(.failed(error.localizedDescription))
            }
        }

        return stream
    }

    private func handleMessage(_ data: Data, continuation: AsyncStream<TLANPairingState>.Continuation) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(TLANMessage.self, from: data)

        switch message.type {
        case "CHALLENGE":
            logger.info("Challenge received")
            continuation.yield(.challengeReceived)
            guard let nonceStr = message.nonce, let nonceData = Data(base64Encoded: nonceStr) else {
                throw TLANError.invalidChallenge
            }

            let hmac = try await securityService.computeHMAC(for: nonceData)
            let response = TLANMessage(type: "CHALLENGE_RESPONSE", hmac: hmac.base64EncodedString())
            try await send(response)

            let info = await LADeviceInfoService.shared.getDeviceInfo()
            let hello = TLANMessage(
                type: "HELLO",
                deviceId: info.appInstallId,
                deviceName: info.deviceName,
                deviceModel: info.deviceModel,
                platform: info.platform,
                appVersion: info.appVersion,
                appInstallId: info.appInstallId
            )
            try await send(hello)
            continuation.yield(.awaitingApproval(countdown: 120))

        case "TRUST_TOKEN":
            logger.info("Trust token received")
            guard let token = message.token,
                  let deviceId = message.deviceId,
                  let gatewayId = message.gatewayId,
                  let expiresAt = message.expiresAt else {
                throw TLANError.invalidMessage
            }

            let trustToken = TLANTrustToken(token: token, deviceId: deviceId, gatewayId: gatewayId, expiresAt: expiresAt)
            try await tokenService.saveToken(trustToken)
            try await send(TLANMessage(type: "ACK"))
            continuation.yield(.paired)
            connection?.disconnect()

        case "APPROVAL_DENIED":
            logger.error("Approval denied")
            continuation.yield(.failed("Approval Denied by Mac"))
            connection?.disconnect()

        default:
            logger.warning("Unknown message type: \(message.type)")
        }
    }

    private func send(_ message: TLANMessage) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)
        try await connection?.send(data: data)
    }
}
