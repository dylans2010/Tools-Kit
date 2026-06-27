import Foundation
import UIKit

class ManualTokenService {
    static let shared = ManualTokenService()

    func validateToken(_ token: String, host: String, port: Int) async throws -> Bool {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .authentication,
            title: "Validating Manual Token",
            description: "Host: \(host)"
        )

        guard let url = URL(string: "ws://\(host):\(port)") else {
            throw OpenClawError.unreachableHost
        }

        let deviceID = "iphone-\(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "unknown")"
        let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

        _ = try await connection.connect()

        let params: [String: AnyCodable] = [
            "device_id": AnyCodable(deviceID),
            "token": AnyCodable(token)
        ]

        // Use a specialized RPC to check token validity
        _ = try await connection.sendRequest("auth.validate", params: params)

        await connection.disconnect()
        return true
    }
}
