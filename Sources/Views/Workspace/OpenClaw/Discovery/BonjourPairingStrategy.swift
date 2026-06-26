import Foundation
import UIKit

struct BonjourPairingStrategy: OpenClawPairingStrategy {
    let name = "Bonjour (Zero-Config)"
    let service: OpenClawDiscoveredService

    func pair() async throws -> OpenClawDevice {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Bonjour Pairing",
            description: "Resolving metadata for: \(service.name)"
        )

        let vendorID = UIDevice.current.identifierForVendor?.uuidString.prefix(8).lowercased() ?? "unknown"
        let deviceID = "iphone-\(vendorID)"

        let device = OpenClawDevice(
            id: deviceID,
            name: service.name,
            host: service.ipAddress ?? service.host,
            port: service.port,
            lastConnected: Date(),
            metadata: ["type": "bonjour"]
        )

        return device
    }
}
