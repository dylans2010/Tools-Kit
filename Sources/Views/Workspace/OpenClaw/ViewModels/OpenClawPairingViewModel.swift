import SwiftUI
import Observation

@MainActor @Observable
final class OpenClawPairingViewModel {
    var step: Int = 0
    var discoveredDevices: [OpenClawDiscoveredService] {
        discoveryService.discoveredServices
    }
    var manualHost: String = ""
    var manualPort: String = "18789"
    var isPairing: Bool = false
    var errorMessage: String?

    private let discoveryService = OpenClawDiscoveryService()

    init() {
    }

    func startDiscovery() {
        errorMessage = nil
        discoveryService.startDiscovery()
    }

    func stopDiscovery() {
        discoveryService.stopDiscovery()
    }

    func pair(with strategy: OpenClawPairingStrategy) async {
        isPairing = true
        errorMessage = nil
        step = 2 // Pairing loading step

        do {
            let device = try await strategy.pair()
            OpenClawDeviceRegistry.shared.register(device)
            step = 3 // Success step
        } catch {
            errorMessage = error.localizedDescription
            step = (strategy is ManualPairingStrategy) ? 1 : 0
        }
        isPairing = false
    }

    func reset() {
        step = 0
        errorMessage = nil
        isPairing = false
    }
}
