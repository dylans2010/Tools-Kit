import SwiftUI
import Observation
import AVFoundation

@MainActor @Observable
class QRCodeViewModel {
    var isScanning = false
    var lastScannedCode: String?
    var error: String?
    var isSuccess = false

    func handleScan(payload: String) async {
        isScanning = false
        lastScannedCode = payload

        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "QR Code Scanned",
            description: "Payload length: \(payload.count)"
        )

        do {
            let info = try QRCodePairingService.shared.parsePayload(payload)
            let deviceID = "iphone-\(UUID().uuidString.prefix(4))"

            guard let url = URL(string: "ws://\(info.host):\(info.port)") else {
                throw OpenClawError.unreachableHost
            }

            let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)
            _ = try await connection.connect()

            var finalToken = info.token

            // If the QR contains a one-time token, exchange it for a permanent one
            if let tempToken = info.token {
                let params: [String: AnyCodable] = [
                    "device_id": AnyCodable(deviceID),
                    "temp_token": AnyCodable(tempToken)
                ]
                let result = try await connection.sendRequest("pair.exchange", params: params)
                if let dict = result.value as? [String: Any], let permToken = dict["token"] as? String {
                    finalToken = permToken
                }
            }

            await connection.disconnect()

            if let tokenToSave = finalToken {
                OpenClawSecureStore.shared.saveToken(tokenToSave, for: deviceID)
            }

            let device = OpenClawDevice(
                id: deviceID,
                name: "QR Gateway (\(info.host))",
                host: info.host,
                port: info.port,
                lastConnected: Date(),
                metadata: ["method": "qr_code"]
            )
            OpenClawDeviceRegistry.shared.register(device)

            isSuccess = true
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .pairing,
                title: "QR Pairing Success",
                description: "Target: \(info.host):\(info.port)"
            )
        } catch {
            self.error = error.localizedDescription
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .pairing,
                title: "QR Pairing Failed",
                description: error.localizedDescription
            )
        }
    }
}
