import Foundation

struct ManualPairingStrategy: OpenClawPairingStrategy {
    let name = "Manual Entry"
    let host: String
    let port: Int

    func pair() async throws -> OpenClawDevice {
        // 1. Validate Input
        guard !host.isEmpty else {
            throw OpenClawError.protocolError("Host cannot be empty")
        }
        guard (1...65535).contains(port) else {
            throw OpenClawError.protocolError("Invalid port number")
        }

        // 2. Attempt Connection and Handshake
        guard let url = URL(string: "ws://\(host):\(port)") else {
            throw OpenClawError.unreachableHost
        }

        let deviceID = UUID().uuidString
        let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

        do {
            _ = try await connection.connect()
            // If connect() succeeds, it means the handshake was successful
            await connection.disconnect()
        } catch {
            throw OpenClawError.handshakeFailed(error.localizedDescription)
        }

        // 3. Register Device
        let device = OpenClawDevice(
            id: deviceID,
            name: "Manual Gateway (\(host))",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "manual"]
        )

        return device
    }
}
