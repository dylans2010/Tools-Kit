import Foundation

struct BonjourPairingStrategy: OpenClawPairingStrategy {
    let name = "Bonjour (Zero-Config)"
    let service: OpenClawDiscoveredService

    func pair() async throws -> OpenClawDevice {
        // In a real scenario, this would involve connecting and getting a permanent token
        let device = OpenClawDevice(
            id: UUID().uuidString,
            name: service.name,
            host: service.host,
            port: service.port,
            lastConnected: Date(),
            metadata: ["type": "bonjour"]
        )
        // Store initial temporary token if needed
        OpenClawSecureStore.shared.saveToken("initial-pair-token", for: device.id)
        return device
    }
}
