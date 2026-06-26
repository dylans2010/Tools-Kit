import Foundation

struct QRPairingStrategy: OpenClawPairingStrategy {
    let name = "QR Code"
    let payload: String

    func pair() async throws -> OpenClawDevice {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "QR Pairing",
            description: "Processing scanned QR payload"
        )
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let host = json["host"] as? String,
              let port = json["port"] as? Int else {
            throw OpenClawError.protocolError("Invalid QR payload")
        }

        guard let url = URL(string: "ws://\(host):\(port)") else {
            throw OpenClawError.unreachableHost
        }

        let deviceID = UUID().uuidString

        // If QR already contains a token, save it
        if let token = json["token"] as? String {
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .authentication,
                title: "QR Token Found",
                description: "Pre-authenticated token detected in QR"
            )
            OpenClawSecureStore.shared.saveToken(token, for: deviceID)
        }

        let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

        do {
            _ = try await connection.connect()
            await connection.disconnect()
        } catch {
            throw OpenClawError.handshakeFailed("QR handshake failed: \(error.localizedDescription)")
        }

        let device = OpenClawDevice(
            id: deviceID,
            name: json["name"] as? String ?? "QR Gateway",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "qr"]
        )

        return device
    }
}
