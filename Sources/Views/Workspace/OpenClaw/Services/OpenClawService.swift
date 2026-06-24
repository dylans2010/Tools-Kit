import Foundation
import Combine

@MainActor
final class OpenClawService: ObservableObject {
    static let shared = OpenClawService()

    @Published var currentConnection: OpenClawGatewayConnection?
    @Published var connectionState: ConnectionState = .idle

    private var cancellables = Set<AnyCancellable>()
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

        // Observe connection state from the actor
        connection.statePublisher
            .receive(on: RunLoop.main)
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

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
        cancellables.removeAll()
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
