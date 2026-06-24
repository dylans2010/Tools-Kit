import Foundation

struct BridgePairingStrategy: OpenClawPairingStrategy {
    let name = "Node Bridge"
    let bridgeURL: URL

    func pair() async throws -> OpenClawDevice {
        // In reality, this would fetch pairing info from the bridge
        let device = OpenClawDevice(
            id: UUID().uuidString,
            name: "Bridged Gateway",
            host: bridgeURL.host ?? "localhost",
            port: bridgeURL.port ?? 3000,
            lastConnected: Date(),
            metadata: ["type": "bridge"]
        )
        return device
    }
}
