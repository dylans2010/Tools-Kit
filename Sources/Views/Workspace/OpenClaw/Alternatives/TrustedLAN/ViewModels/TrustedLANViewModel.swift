import SwiftUI
import Observation

@MainActor @Observable
class TrustedLANViewModel {
    var discoveredServices: [OpenClawDiscoveredService] {
        OpenClawDiscoveryService.shared.discoveredServices
    }
    var isPairing = false
    var pairingStatus: String = "Idle"
    var error: String?

    func startDiscovery() {
        OpenClawDiscoveryService.shared.startDiscovery()
    }

    func pair(with service: OpenClawDiscoveredService) async {
        isPairing = true
        pairingStatus = "Requesting Approval..."
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Trusted LAN Pairing",
            description: "Requesting approval from \(service.name)"
        )

        do {
            guard let url = service.url else { throw OpenClawError.unreachableHost }
            let deviceID = "iphone-\(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "unknown")"
            let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

            _ = try await connection.connect()

            let params: [String: AnyCodable] = [
                "device_id": AnyCodable(deviceID),
                "device_name": AnyCodable(UIDevice.current.name),
                "method": AnyCodable("trusted_lan")
            ]

            let result = try await connection.sendRequest("pair", params: params)
            await connection.disconnect()

            guard let dict = result.value as? [String: Any], let token = dict["token"] as? String else {
                throw OpenClawError.protocolError("No token returned")
            }

            TrustedLANPairingService.shared.saveTrustToken(token, for: deviceID)

            let device = OpenClawDevice(
                id: deviceID,
                name: service.name,
                host: service.ipAddress ?? service.host,
                port: service.port,
                lastConnected: Date(),
                metadata: ["method": "trusted_lan"]
            )

            OpenClawDeviceRegistry.shared.register(device)
            pairingStatus = "Paired!"
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .pairing,
                title: "Pairing Successful",
                description: "Trust established with \(service.name)"
            )
        } catch {
            self.error = error.localizedDescription
            pairingStatus = "Failed"
        }
        isPairing = false
    }
}
