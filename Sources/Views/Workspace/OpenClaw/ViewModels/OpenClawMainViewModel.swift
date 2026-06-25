import SwiftUI
import Combine

@MainActor
final class OpenClawMainViewModel: ObservableObject {
    @Published var connectionStatus: String = "Disconnected"
    @Published var activeDeviceName: String = "None"
    @Published var latency: String = "-- ms"
    @Published var isConnecting: Bool = false
    @Published var lastError: String?

    private let service = OpenClawService.shared
    private let registry = OpenClawDeviceRegistry.shared
    private let diagnostics = OpenClawDiagnosticsManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        service.$connectionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateStatus(state)
            }
            .store(in: &cancellables)

        registry.$activeDeviceID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeDeviceName = self?.registry.activeDevice?.name ?? "None"
            }
            .store(in: &cancellables)

        diagnostics.$metrics
            .compactMap { $0.last(where: { $0.name == "latency" }) }
            .receive(on: RunLoop.main)
            .sink { [weak self] metric in
                self?.latency = metric.value
            }
            .store(in: &cancellables)
    }

    private func updateStatus(_ state: ConnectionState) {
        isConnecting = (state == .connecting || state == .socketConnected || state == .authenticating || state == .waitingChallenge)

        switch state {
        case .idle:
            connectionStatus = "Disconnected"
            lastError = nil
        case .connecting:
            connectionStatus = "Connecting..."
        case .socketConnected:
            connectionStatus = "Socket Connected..."
        case .waitingChallenge:
            connectionStatus = "Waiting for challenge..."
        case .authenticating:
            connectionStatus = "Authenticating..."
        case .connected:
            connectionStatus = "Connected"
            lastError = nil
        case .failed(let error):
            connectionStatus = "Error"
            lastError = error
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
