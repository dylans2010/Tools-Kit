import Foundation

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false

    private var webSocketTask: URLSessionWebSocketTask?

    private init() {}

    func connect(to url: URL) {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
    }

    func send(message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
}
