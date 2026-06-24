import Foundation
import Observation

@MainActor
@Observable
final class OpenClawPairingViewModel {
    enum Step: Int, CaseIterable {
        case requirements
        case discovery
        case manualInput
        case connecting
        case success
    }

    var currentStep: Step = .requirements
    var selectedDevice: OpenClawDevice?
    var manualHost: String = ""
    var manualPort: String = "18789"
    var token: String = ""
    var isConnecting = false
    var errorMessage: String?

    private let discoveryService = OpenClawDiscoveryService()
    private let registry = OpenClawDeviceRegistry.shared

    var discoveredDevices: [OpenClawDevice] {
        discoveryService.discoveredDevices
    }

    func startDiscovery() {
        discoveryService.startScanning()
    }

    func stopDiscovery() {
        discoveryService.stopScanning()
    }

    func pair(device: OpenClawDevice) async {
        guard let url = device.url else {
            errorMessage = "Invalid gateway URL"
            return
        }

        isConnecting = true
        errorMessage = nil

        let connection = OpenClawGatewayConnection(url: url)
        do {
            try await connection.connect(token: token)
            var pairedDevice = device
            pairedDevice.lastConnected = Date()
            registry.register(pairedDevice)
            try OpenClawSecureStore.shared.saveToken(token, for: device.id)
            currentStep = .success
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
        await connection.disconnect()
    }

    func pairManual() async {
        guard let port = Int(manualPort) else {
            errorMessage = "Invalid port"
            return
        }

        let device = OpenClawDevice(
            id: UUID().uuidString,
            name: manualHost,
            host: manualHost,
            port: port
        )
        await pair(device: device)
    }
}
