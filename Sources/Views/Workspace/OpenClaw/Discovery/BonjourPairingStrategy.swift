import Foundation
import UIKit

struct BonjourPairingStrategy: OpenClawPairingStrategy {
    let name = "Bonjour (Zero-Config)"
    let service: OpenClawDiscoveredService

    func pair() async throws -> OpenClawDevice {
        guard let url = service.url else {
            throw OpenClawError.unreachableHost
        }

        let vendorID = UIDevice.current.identifierForVendor?.uuidString.prefix(8).lowercased() ?? "unknown"
        let deviceID = "iphone-\(vendorID)"
        let connection = OpenClawGatewayConnection(url: url, deviceID: deviceID)

        do {
            _ = try await connection.connect()
            // Token is extracted and saved automatically during connect() if provided by gateway
            await connection.disconnect()
        } catch {
            throw OpenClawError.handshakeFailed("Bonjour handshake failed: \(error.localizedDescription)")
        }

        let device = OpenClawDevice(
            id: deviceID,
            name: service.name,
            host: service.host,
            port: service.port,
            lastConnected: Date(),
            metadata: ["type": "bonjour"]
        )

        return device
    }
}
