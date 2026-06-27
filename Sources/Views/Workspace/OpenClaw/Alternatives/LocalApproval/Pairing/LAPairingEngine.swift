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

import Foundation

public actor LAPairingEngine {
    private var connection: LAWebSocketConnection?
    private let tokenService = LATokenService.shared

    public init() {}

    public func requestApproval(url: URL) async throws -> AsyncStream<LAPairingState> {
        let (stream, continuation) = AsyncStream.makeStream(of: LAPairingState.self)
        let c = LAWebSocketConnection(url: url)
        self.connection = c
        let dataStream = await c.connect()

        let info = await LADeviceInfoService.shared.getDeviceInfo()
        let hello = LAMessage(type: "HELLO", deviceInfo: info)
        let data = try JSONEncoder().encode(hello)
        try await c.send(data: data)
        continuation.yield(.awaitingApproval)

        Task {
            for await d in dataStream {
                let msg = try JSONDecoder().decode(LAMessage.self, from: d)
                if msg.type == "TRUST_TOKEN", let t = msg.token {
                    try await tokenService.saveToken(t)
                    continuation.yield(.paired)
                    break
                } else if msg.type == "DENIED" {
                    continuation.yield(.failed("Denied"))
                    break
                }
            }
        }
        return stream
    }
}
