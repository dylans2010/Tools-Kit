import Foundation

/// Manages real-time WebSocket connections for live updates and collaboration.
final class WebSocketManager: ObservableObject {
    nonisolated(unsafe) static let shared = WebSocketManager()

    private var socket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    private let queue = DispatchQueue(label: "io.toolskit.websocket", attributes: .concurrent)
    private var _callbacks: [String: ([String: Any]) -> Void] = [:]

    private var callbacks: [String: ([String: Any]) -> Void] {
        get { queue.sync { _callbacks } }
        set { queue.async(flags: .barrier) { self._callbacks = newValue } }
    }

    private init() {}

    func connect() {
        print("[WebSocketManager] Connecting to real-time service...")
        guard let url = URL(string: "wss://api.toolskit.io/ws") else { return }
        socket = session.webSocketTask(with: url)
        socket?.resume()
        listen()
    }

    func subscribe(_ topic: String, callback: @escaping ([String: Any]) -> Void) {
        callbacks[topic] = callback
        print("[WebSocketManager] Subscribed to topic: \(topic)")
    }

    func send(topic: String, payload: [String: Any]) {
        let message: [String: Any] = ["topic": topic, "payload": payload]
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        socket?.send(.string(jsonString)) { error in
            if let error = error {
                print("[WebSocketManager] Send error: \(error.localizedDescription)")
            }
        }
    }

    private func listen() {
        socket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.listen()
            case .failure(let error):
                print("[WebSocketManager] Receive error: \(error.localizedDescription)")
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let topic = json["topic"] as? String,
              let payload = json["payload"] as? [String: Any] else { return }

        if let callback = callbacks[topic] {
            DispatchQueue.main.async {
                callback(payload)
            }
        }
    }
}
