import SwiftUI
import Combine

@MainActor
final class OpenClawPairingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var discoveredDevices: [OpenClawDiscoveredService] = []
    @Published var manualHost: String = ""
    @Published var manualPort: String = "18789"
    @Published var isPairing: Bool = false
    @Published var errorMessage: String?

    private let discoveryService = OpenClawDiscoveryService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        discoveryService.$discoveredServices
            .receive(on: RunLoop.main)
            .assign(to: \.discoveredDevices, on: self)
            .store(in: &cancellables)
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
