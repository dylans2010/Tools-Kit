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

    private let discoveryService = OpenClawDiscoveryService.shared

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

            // Initiate connection through shared service
            await OpenClawService.shared.connect(to: device)

            // Wait for service to reach ready state using the stream to avoid busy-wait
            guard let connection = OpenClawService.shared.currentConnection else {
                 throw OpenClawError.connectionFailed("No active connection")
            }

            for await state in connection.stateStream {
                if state == .ready {
                    step = 3 // Success step
                    break
                }
                if case .failed(let reason) = state {
                    throw OpenClawError.connectionFailed(String(describing: reason))
                }
                // If it gets to pairing state, it means we need to call pair() manually
                // or wait for the user to trigger it if the UI allows.
                // For a seamless flow, we can trigger pair() if we are in the pairing step.
                if state == .pairing {
                    Task {
                        try? await OpenClawService.shared.pair()
                    }
                }
            }
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
