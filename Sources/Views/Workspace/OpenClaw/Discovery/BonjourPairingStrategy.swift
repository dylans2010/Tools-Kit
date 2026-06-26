import Foundation
import UIKit

struct BonjourPairingStrategy: OpenClawPairingStrategy {
    let name = "Bonjour (Zero-Config)"
    let service: OpenClawDiscoveredService

    func pair() async throws -> OpenClawDevice {
        await OpenClawDiagnosticsManager.shared.log("Bonjour pairing metadata resolving for: \(service.name)", type: .info)

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
