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
        discoveryService.startDiscovery()
    }

    func stopDiscovery() {
        discoveryService.stopDiscovery()
    }

    func pair(with strategy: OpenClawPairingStrategy) async {
        isPairing = true
        errorMessage = nil
        do {
            let device = try await strategy.pair()
            OpenClawDeviceRegistry.shared.register(device)
            step = 3 // Success step
        } catch {
            errorMessage = error.localizedDescription
        }
        isPairing = false
    }
}
