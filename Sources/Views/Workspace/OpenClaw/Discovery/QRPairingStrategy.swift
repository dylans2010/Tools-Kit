import Foundation

struct QRPairingStrategy: OpenClawPairingStrategy {
    let name = "QR Code"
    let payload: String

    func pair() async throws -> OpenClawDevice {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let host = json["host"] as? String,
              let port = json["port"] as? Int else {
            throw OpenClawError.protocolError("Invalid QR payload")
        }

        let device = OpenClawDevice(
            id: UUID().uuidString,
            name: json["name"] as? String ?? "QR Gateway",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "qr"]
        )

        if let token = json["token"] as? String {
            OpenClawSecureStore.shared.saveToken(token, for: device.id)
        }

        return device
    }
}
