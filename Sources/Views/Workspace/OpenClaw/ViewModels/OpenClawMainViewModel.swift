import Foundation
import Observation

@MainActor
@Observable
final class OpenClawMainViewModel {
    static let shared = OpenClawMainViewModel()

    var devices: [OpenClawDevice] = []
    var activeConnection: OpenClawGatewayConnection?
    var gatewayService: OpenClawGatewayService?
    var isConnected = false
    var logs: [String] = []

    private let registry = OpenClawDeviceRegistry.shared

    init() {
        self.devices = registry.devices
    }

    func refreshDevices() {
        self.devices = registry.devices
    }

    func connect(to device: OpenClawDevice) async {
        guard let token = OpenClawSecureStore.shared.getToken(for: device.id) else {
            logs.append("Error: No token found for \(device.name)")
            return
        }

        guard let url = device.url else {
            logs.append("Error: Invalid URL for \(device.name)")
            return
        }

        let connection = OpenClawGatewayConnection(url: url)
        activeConnection = connection
        gatewayService = OpenClawGatewayService(connection: connection)

        do {
            try await connection.connect(token: token)
            isConnected = true
            logs.append("Connected to \(device.name)")

            Task {
                for await event in await connection.events() {
                    self.logs.append("Event: \(event.event)")
                }
            }
        } catch {
            logs.append("Connection failed: \(error.localizedDescription)")
            isConnected = false
        }
    }

    func disconnect() async {
        await activeConnection?.disconnect()
        activeConnection = nil
        gatewayService = nil
        isConnected = false
        logs.append("Disconnected")
    }

    func identify() async {
        try? await gatewayService?.identify()
    }

    func restart() async {
        try? await gatewayService?.restart()
    }

    func clearAllTokens() {
        for device in devices {
            OpenClawSecureStore.shared.deleteToken(for: device.id)
        }
        logs.append("All security tokens cleared")
    }
}
