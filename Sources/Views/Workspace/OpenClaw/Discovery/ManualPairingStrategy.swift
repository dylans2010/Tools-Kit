import Foundation

struct ManualPairingStrategy: OpenClawPairingStrategy {
    let name = "Manual Entry"
    let host: String
    let port: Int

    func pair() async throws -> OpenClawDevice {
        // Validation would happen here
        let device = OpenClawDevice(
            id: UUID().uuidString,
            name: "Manual Gateway (\(host))",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "manual"]
        )
        return device
    }
}
