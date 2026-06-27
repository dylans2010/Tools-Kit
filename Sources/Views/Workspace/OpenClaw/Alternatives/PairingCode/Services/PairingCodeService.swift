import Foundation
import UIKit

class PairingCodeService {
    static let shared = PairingCodeService()

    func validateCode(_ code: String, gatewayURL: URL) async throws -> String {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .handshake,
            title: "Validating Pairing Code",
            description: "Target: \(gatewayURL.host ?? "unknown")"
        )

        let deviceID = "iphone-\(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "unknown")"
        let connection = OpenClawGatewayConnection(url: gatewayURL, deviceID: deviceID)

        // We use the pair RPC method with a code parameter
        let params: [String: AnyCodable] = [
            "device_id": AnyCodable(deviceID),
            "device_name": AnyCodable(UIDevice.current.name),
            "pairing_code": AnyCodable(code)
        ]

        // Connect first (this will trigger the application handshake)
        _ = try await connection.connect()

        // Send the pairing request
        let result = try await connection.sendRequest("pair", params: params)

        await connection.disconnect()

        if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
            return token
        } else {
            throw OpenClawError.protocolError("Server did not return a token")
        }
    }
}
