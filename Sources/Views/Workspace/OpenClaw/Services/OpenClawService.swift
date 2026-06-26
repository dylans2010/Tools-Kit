import Foundation
import Observation

@MainActor @Observable
final class OpenClawService {
    static let shared = OpenClawService()

    var currentConnection: OpenClawGatewayConnection?
    var connectionState: OpenClawConnectionState = .idle

    private var stateObservationTask: Task<Void, Never>?
    private let registry = OpenClawDeviceRegistry.shared
    private let logger = OpenClawLoggerService.shared
    private let discovery = OpenClawDiscoveryService.shared

    private init() {
    }

    func connectToActiveDevice() async {
        guard let device = registry.activeDevice else {
            OpenClawLoggerService.shared.log(
                level: .warning,
                category: .general,
                title: "Connection Aborted",
                description: "No active device registered"
            )
            return
        }
        await connect(to: device)
    }

    func connect(to device: OpenClawDevice) async {
        guard let url = URL(string: "ws://\(device.host):\(device.port)") else {
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .general,
                title: "Invalid URL",
                description: "Host: \(device.host), Port: \(device.port)"
            )
            return
        }

        if let existing = currentConnection {
            let state = await existing.getState()
            if state != .idle {
                if case .failed = state {
                    // Allow retry if failed
                } else {
                    OpenClawLoggerService.shared.log(
                        level: .info,
                        category: .general,
                        title: "Already Connected",
                        description: "Connection to \(device.name) is active"
                    )
                    return
                }
            }
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
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .gateway,
                title: "Service Connected",
                description: "Established connection to \(device.name)"
            )

            Task {
                for await event in stream {
                    OpenClawMessageBus.shared.publish(event)
                    OpenClawLoggerService.shared.log(
                        level: .debug,
                        category: .session,
                        title: "Gateway Event",
                        description: event.event
                    )
                }
            }
        } catch {
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .gateway,
                title: "Connection Failed",
                description: error.localizedDescription,
                error: error
            )
        }
    }

    func disconnect() async {
        await currentConnection?.disconnect()
        stateObservationTask?.cancel()
        stateObservationTask = nil
        self.currentConnection = nil
        self.connectionState = .idle
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .gateway,
            title: "Manual Disconnect",
            description: "User initiated disconnect"
        )
    }

    func pair() async throws {
        guard let connection = currentConnection else {
            throw OpenClawError.connectionFailed("No active connection")
        }
        try await connection.pair()
    }

    func sendRPC(_ method: String, params: [String: AnyCodable] = [:]) async throws -> AnyCodable {
        guard let connection = currentConnection else {
            throw OpenClawError.connectionFailed("No active connection")
        }
        return try await connection.sendRequest(method, params: params)
    }
}
