import Foundation
import Observation
import Network
import OSLog

@Observable @MainActor
public final class MTPairingViewModel {
    public var state: PairingState = .idle
    public var selectedEndpoint: NWEndpoint?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "manual-token")

    public init() {}

    public func pair(token: String, endpoint: NWEndpoint) async {
        state = .connecting
        let transport = OpenClawTransport()
        do {
            try await transport.connect(to: endpoint, using: .tcp)
            state = .authenticating

            let message = TLANMessage(type: "TOKEN_PAIR", token: token)
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            try await transport.send(data)

            let responseData = try await transport.receive()
            let response = try JSONDecoder().decode(TLANMessage.self, from: responseData)

            if response.type == "PAIR_SUCCESS" {
                state = .paired
            } else {
                state = .failed("Token validation failed")
            }
        } catch {
            state = .failed(error.localizedDescription)
            logger.error("Pairing failed: \(error.localizedDescription)")
        }
        transport.disconnect()
    }
}
