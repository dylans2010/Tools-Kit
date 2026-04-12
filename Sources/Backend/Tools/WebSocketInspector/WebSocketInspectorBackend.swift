import Foundation

struct WebSocketMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: Direction
    let content: String

    enum Direction { case sent, received, system }
}

@MainActor
final class WebSocketInspectorBackend: ObservableObject {
    @Published var urlString = "wss://echo.websocket.org"
    @Published var messages: [WebSocketMessage] = []
    @Published var isConnected = false
    @Published var statusMessage = "Disconnected"
    @Published var pingMs: Double = 0
    @Published var sendText = ""

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var connectedAt: Date?

    var connectionAge: String {
        guard let t = connectedAt else { return "–" }
        let s = Int(Date().timeIntervalSince(t))
        return "\(s)s"
    }

    func connect() {
        guard let url = URL(string: urlString), !isConnected else { return }
        session = URLSession(configuration: .default)
        task = session?.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        connectedAt = Date()
        statusMessage = "Connected"
        addMessage("Connected to \(urlString)", direction: .system)
        receiveLoop()
        measurePing()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
        statusMessage = "Disconnected"
        connectedAt = nil
        addMessage("Disconnected", direction: .system)
    }

    func send() {
        let text = sendText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let task = task else { return }
        task.send(.string(text)) { _ in }
        addMessage(text, direction: .sent)
        sendText = ""
    }

    func clearLog() {
        messages.removeAll()
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let msg):
                    switch msg {
                    case .string(let text): self?.addMessage(text, direction: .received)
                    case .data(let data): self?.addMessage("[\(data.count) bytes]", direction: .received)
                    @unknown default: break
                    }
                    self?.receiveLoop()
                case .failure(let error):
                    self?.isConnected = false
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func measurePing() {
        guard isConnected else { return }
        let start = Date()
        task?.sendPing { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                if error == nil {
                    self.pingMs = Date().timeIntervalSince(start) * 1000
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                self.measurePing()
            }
        }
    }

    private func addMessage(_ content: String, direction: WebSocketMessage.Direction) {
        let msg = WebSocketMessage(timestamp: Date(), direction: direction, content: content)
        messages.insert(msg, at: 0)
        if messages.count > 100 { messages.removeLast() }
    }
}
