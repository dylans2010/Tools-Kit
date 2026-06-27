import Foundation
import UIKit

class LocalApprovalService {
    static let shared = LocalApprovalService()

    func initiateApproval(service: OpenClawDiscoveredService) async throws -> String {
        guard let url = service.url else {
            throw OpenClawError.unreachableHost
        }

        let deviceID = "iphone-\(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "unknown")"
        let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Local Approval Requested",
            description: "Waiting for user to click Allow on \(service.name)"
        )

        _ = try await connection.connect()

        let params: [String: AnyCodable] = [
            "device_id": AnyCodable(deviceID),
            "device_name": AnyCodable(UIDevice.current.name),
            "approval_type": AnyCodable("local_dialog")
        ]

        // This request will hang on the server until the user approves or denies
        let result = try await connection.sendRequest("pair", params: params)

        await connection.disconnect()

        if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
            return token
        } else {
            throw OpenClawError.protocolError("Pairing denied or failed")
        }
    }
}
