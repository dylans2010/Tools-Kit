import SwiftUI
import Combine

@MainActor
final class OpenClawMainViewModel: ObservableObject {
    @Published var connectionStatus: String = "Disconnected"
    @Published var activeDeviceName: String = "None"
    @Published var latency: String = "-- ms"

    private let service = OpenClawService.shared
    private let registry = OpenClawDeviceRegistry.shared
    private let diagnostics = OpenClawDiagnosticsManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        service.$connectionState
            .sink { [weak self] state in
                self?.updateStatus(state)
            }
            .store(in: &cancellables)

        registry.$activeDeviceID
            .sink { [weak self] _ in
                self?.activeDeviceName = self?.registry.activeDevice?.name ?? "None"
            }
            .store(in: &cancellables)

        diagnostics.$metrics
            .filter { $0.name == "latency" }
            .sink { [weak self] metric in
                self?.latency = metric.value
            }
            .store(in: &cancellables)
    }

    private func updateStatus(_ state: ConnectionState) {
        switch state {
        case .idle: connectionStatus = "Disconnected"
        case .connecting: connectionStatus = "Connecting..."
        case .authenticating: connectionStatus = "Authenticating..."
        case .connected: connectionStatus = "Connected"
        case .failed(let error): connectionStatus = "Error: \(error.localizedDescription)"
        }
    }

    func connect() {
        Task {
            await service.connectToActiveDevice()
        }
    }

    func disconnect() {
        Task {
            await service.disconnect()
        }
    }
}
