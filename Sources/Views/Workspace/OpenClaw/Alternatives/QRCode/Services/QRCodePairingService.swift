import Foundation
import AVFoundation

class QRCodePairingService {
    static let shared = QRCodePairingService()

    func parsePayload(_ payload: String) throws -> (host: String, port: Int, token: String?) {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenClawError.protocolError("Invalid QR format")
        }

        guard let host = json["host"] as? String,
              let port = json["port"] as? Int else {
            throw OpenClawError.protocolError("Missing host or port in QR")
        }

        let token = json["token"] as? String
        return (host, port, token)
    }
}
