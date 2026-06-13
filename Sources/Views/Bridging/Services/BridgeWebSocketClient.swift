import Foundation
import Combine

public final class BridgeWebSocketClient: NSObject, ObservableObject {
    @Published public private(set) var connectionState: BridgeConnectionState = .disconnected
    @Published public private(set) var latency: Int = 0

    private var socket: URLSessionWebSocketTask?
    private var timer: AnyCancellable?
    private var reconnectTimer: AnyCancellable?
    private var lastPingSent: Date?
    private let session = URLSession(configuration: .default)

    private var currentURL: URL?
    private var currentToken: String?

    public let messagePublisher = PassthroughSubject<BridgeMessage, Never>()
    public let commandPublisher = PassthroughSubject<BridgeCommand, Never>()

    public override init() {
        super.init()
    }

    public func connect(to url: URL, token: String) {
        self.currentURL = url
        self.currentToken = token

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        socket = session.webSocketTask(with: request)
        socket?.resume()

        connectionState = .connecting
        listen()
        startHeartbeat()
    }

    public func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        timer?.cancel()
        reconnectTimer?.cancel()
        connectionState = .disconnected
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.connectionState = .connected
                self.listen()

            case .failure(let error):
                print("[\(Date().timeIntervalSince1970)] [WebSocket] Receive error: \(error.localizedDescription)")
                self.handleDisconnect()
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            parseIncomingData(data)
        case .data(let data):
            parseIncomingData(data)
        @unknown default:
            break
        }
    }

    private func parseIncomingData(_ data: Data) {
        let decoder = JSONDecoder()

        if let msg = try? decoder.decode(BridgeMessage.self, from: data) {
            DispatchQueue.main.async {
                self.messagePublisher.send(msg)
            }
        } else if let cmd = try? decoder.decode(BridgeCommand.self, from: data) {
            DispatchQueue.main.async {
                self.commandPublisher.send(cmd)
            }
        } else {
            // Check for heartbeat response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["type"] as? String == "pong",
               let sentTime = lastPingSent {
                let diff = Date().timeIntervalSince(sentTime)
                DispatchQueue.main.async {
                    self.latency = Int(diff * 1000)
                }
            }
        }
    }

    public func send(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        socket?.send(message) { error in
            if let error = error {
                print("[\(Date().timeIntervalSince1970)] [WebSocket] Send error: \(error.localizedDescription)")
            }
        }
    }

    private func startHeartbeat() {
        timer?.cancel()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendPing()
            }
    }

    private func sendPing() {
        lastPingSent = Date()
        let ping = ["type": "ping", "timestamp": lastPingSent?.timeIntervalSince1970 ?? 0] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: ping),
           let string = String(data: data, encoding: .utf8) {
            send(string)
        }
    }

    private func handleDisconnect() {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        reconnectTimer?.cancel()
        reconnectTimer = Just(())
            .delay(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self = self, let url = self.currentURL, let token = self.currentToken else { return }
                print("[\(Date().timeIntervalSince1970)] [WebSocket] Attempting to reconnect...")
                self.connect(to: url, token: token)
            }
    }
}
