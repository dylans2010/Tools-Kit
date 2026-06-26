import Foundation
import Observation

@MainActor @Observable
final class OpenClawService {
    static let shared = OpenClawService()

    var currentConnection: OpenClawGatewayConnection?
    var connectionState: ConnectionState = .idle

    private var stateObservationTask: Task<Void, Never>?
    private let registry = OpenClawDeviceRegistry.shared
    private let diagnostics = OpenClawDiagnosticsManager.shared

    private init() {
    }

    func connectToActiveDevice() async {
        guard let device = registry.activeDevice else {
            diagnostics.log("No active device to connect to")
            return
        }

        guard let url = URL(string: "ws://\(device.host):\(device.port)") else {
            diagnostics.log("Invalid URL for device: \(device.host)")
            return
        }

        let connection = OpenClawGatewayConnection(url: url, deviceID: device.id)
        self.currentConnection = connection

        // Observe connection state from the actor via AsyncStream
        stateObservationTask?.cancel()
        stateObservationTask = Task { [weak self] in
            for await state in connection.stateStream {
                self?.connectionState = state
            }
        }

        do {
            let stream = try await connection.connect()
            diagnostics.log("Connected to \(device.name)")

            Task {
                for await event in stream {
                    OpenClawMessageBus.shared.publish(event)
                    diagnostics.log("Received event: \(event.event)")
                }
            }
        } catch {
            diagnostics.log("Failed to connect: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        await currentConnection?.disconnect()
        stateObservationTask?.cancel()
        stateObservationTask = nil
        self.currentConnection = nil
        self.connectionState = .idle
        diagnostics.log("Disconnected")
    }

    func sendRPC(_ method: String, params: [String: AnyCodable] = [:]) async throws -> AnyCodable {
        guard let connection = currentConnection else {
            throw OpenClawError.connectionFailed("No active connection")
        }
        return try await connection.sendRequest(method, params: params)
    }
}
