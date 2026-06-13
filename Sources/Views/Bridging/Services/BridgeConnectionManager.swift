import Foundation
import Combine

public final class BridgeConnectionManager: ObservableObject {
    public static let shared = BridgeConnectionManager()

    @Published public private(set) var activeDevice: BridgeDevice?
    @Published public private(set) var connectionState: BridgeConnectionState = .disconnected

    private let wsClient = BridgeWebSocketClient()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupBindings()
    }

    private func setupBindings() {
        wsClient.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)
    }

    public func selectDevice(_ device: BridgeDevice) {
        disconnect()
        self.activeDevice = device
    }

    public func connect() {
        guard let device = activeDevice,
              let token = BridgeSessionManager.shared.getToken(for: device.id) else {
            self.connectionState = .error(.unauthorizedAccess)
            return
        }

        var components = URLComponents(url: device.hostURL, resolvingAgainstBaseURL: true)
        components?.port = device.port
        components?.scheme = device.hostURL.scheme == "https" ? "wss" : "ws"

        guard let baseURL = components?.url else {
            self.connectionState = .error(.unreachableHost)
            return
        }

        let wsURL = baseURL.appendingPathComponent("ws")
        wsClient.connect(to: wsURL, token: token)

        BridgeSessionManager.shared.updateLastConnected(for: device.id)
    }

    public func disconnect() {
        wsClient.disconnect()
        self.connectionState = .disconnected
    }

    public var currentLatency: Int {
        wsClient.latency
    }

    public var messagePublisher: PassthroughSubject<BridgeMessage, Never> {
        wsClient.messagePublisher
    }

    public var commandPublisher: PassthroughSubject<BridgeCommand, Never> {
        wsClient.commandPublisher
    }

    public func sendMessage(_ content: String) {
        guard connectionState == .connected else { return }
        // We don't create a BridgeMessage here anymore, we just send the raw text
        // or a specific command wrapper if the protocol requires it.
        // For now, sending as a simple JSON with "content" field.
        let payload = ["type": "message", "content": content]
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let string = String(data: data, encoding: .utf8) {
            wsClient.send(string)
        }
    }

    public func approveCommand(_ command: BridgeCommand) {
        var approved = command
        approved.status = .approved
        if let data = try? JSONEncoder().encode(approved),
           let string = String(data: data, encoding: .utf8) {
            wsClient.send(string)
        }
    }

    public func rejectCommand(_ command: BridgeCommand) {
        var rejected = command
        rejected.status = .rejected
        if let data = try? JSONEncoder().encode(rejected),
           let string = String(data: data, encoding: .utf8) {
            wsClient.send(string)
        }
    }
}
