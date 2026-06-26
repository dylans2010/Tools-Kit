import SwiftUI
import Observation

@MainActor @Observable
final class OpenClawMainViewModel {
    var connectionStatus: String = "Disconnected"
    var activeDeviceName: String = "None"
    var latency: String = "-- ms"
    var isConnecting: Bool = false
    var lastError: String?

    private let service = OpenClawService.shared
    private let registry = OpenClawDeviceRegistry.shared
    private let diagnostics = OpenClawDiagnosticsManager.shared

    init() {
        // SwiftUI's @Observable handles data flow, but we update our derived properties
        observeChanges()
    }

    private func observeChanges() {
        withObservationTracking {
            updateStatus(service.connectionState)
            activeDeviceName = registry.activeDevice?.name ?? "None"
            if let latencyMetric = diagnostics.metrics.last(where: { $0.name == "latency" }) {
                latency = latencyMetric.value
            }
        } onChange: {
            Task { @MainActor in
                self.observeChanges()
            }
        }
    }

    private func updateStatus(_ state: ConnectionState) {
        isConnecting = ( {
            switch state {
            case .connecting, .socketConnected, .waitingChallenge, .authenticating, .reconnecting: return true
            default: return false
            }
        }() )

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
        case .failed(let reason):
            connectionStatus = "Error"
            lastError = String(describing: reason)
        case .reconnecting(let attempt):
            connectionStatus = "Reconnecting (Attempt \(attempt + 1))..."
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
