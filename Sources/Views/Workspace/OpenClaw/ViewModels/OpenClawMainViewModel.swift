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
    private let logger = OpenClawLoggerService.shared

    init() {
        // SwiftUI's @Observable handles data flow, but we update our derived properties
        observeChanges()
    }

    private func observeChanges() {
        withObservationTracking {
            updateStatus(service.connectionState)
            activeDeviceName = registry.activeDevice?.name ?? "None"
            // Latency was managed by old diagnostics manager metrics.
            // In the new system, we'd look for RPC response times if needed.
            latency = "-- ms"
        } onChange: {
            Task { @MainActor in
                self.observeChanges()
            }
        }
    }

    private func updateStatus(_ state: OpenClawConnectionState) {
        isConnecting = ( {
            switch state {
            case .discovering, .gatewaySelected, .resolvingAuthentication, .pairing, .connecting, .socketConnected, .waitingForChallenge, .challenged, .authenticating: return true
            default: return false
            }
        }() )

        switch state {
        case .idle, .disconnected:
            connectionStatus = "Disconnected"
            lastError = nil
        case .discovering:
            connectionStatus = "Discovering..."
        case .gatewaySelected:
            connectionStatus = "Gateway Selected..."
        case .resolvingAuthentication:
            connectionStatus = "Resolving Authentication..."
        case .pairing:
            connectionStatus = "Pairing..."
        case .connecting:
            connectionStatus = "Connecting..."
        case .socketConnected:
            connectionStatus = "Socket Connected..."
        case .waitingForChallenge:
            connectionStatus = "Waiting for challenge..."
        case .challenged:
            connectionStatus = "Challenge received..."
        case .authenticating:
            connectionStatus = "Authenticating..."
        case .authenticated, .ready:
            connectionStatus = "Connected"
            lastError = nil
        case .disconnecting:
            connectionStatus = "Disconnecting..."
        case .failed(let reason):
            connectionStatus = "Error"
            lastError = String(describing: reason)
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
