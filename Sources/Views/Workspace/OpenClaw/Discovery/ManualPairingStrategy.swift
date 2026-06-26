import Foundation
import UIKit

struct ManualPairingStrategy: OpenClawPairingStrategy {
    let name = "Manual Entry"
    let host: String
    let port: Int

    func pair() async throws -> OpenClawDevice {
        // 1. Validate Input
        guard !host.isEmpty else {
            throw OpenClawError.protocolError("Host cannot be empty")
        }
        guard (1...65535).contains(port) else {
            throw OpenClawError.protocolError("Invalid port number")
        }

        let vendorID = UIDevice.current.identifierForVendor?.uuidString.prefix(8).lowercased() ?? "unknown"
        let deviceID = "iphone-\(vendorID)"

        // 2. Register Device Metadata
        let device = OpenClawDevice(
            id: deviceID,
            name: "Manual Gateway (\(host))",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "manual"]
        )

        return device
    }
}
