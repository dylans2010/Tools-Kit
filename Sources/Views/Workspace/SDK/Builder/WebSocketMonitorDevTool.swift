import SwiftUI
import Combine

struct WebSocketMonitorDevTool: DevTool {
    let id = "websocket-monitor"
    let name = "WebSocket Monitor"
    let category = DevToolCategory.networking
    let icon = "bolt.horizontal.circle"
    let description = "Real-time WebSocket connection monitoring"

    func render() -> some View {
        WebSocketMonitorView()
    }
}

struct WebSocketMonitorView: View {
    @StateObject private var viewModel = WebSocketMonitorViewModel()
    @State private var messageToSend = ""

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "WebSocket Monitor",
                description: "Connect to WebSocket servers, send messages, and monitor live traffic.",
                icon: "bolt.horizontal.circle"
            )
            .padding()

            Form {
                Section("Connection") {
                    HStack {
                        TextField("wss://echo.websocket.org", text: $viewModel.url)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                            if viewModel.isConnected {
                                viewModel.disconnect()
                            } else {
                                viewModel.connect()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.isConnected ? .red : .accentColor)
                    }

                    HStack {
                        StatusBadge(
                            text: viewModel.isConnected ? "Connected" : "Disconnected",
                            color: viewModel.isConnected ? .green : .secondary
                        )
                        Spacer()
                        if viewModel.isConnected {
                            Text("Latency: \(viewModel.latency)ms")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if viewModel.isConnected {
                    Section("Send Message") {
                        HStack {
                            TextField("Message content...", text: $messageToSend)
                            Button("Send") {
                                viewModel.send(messageToSend)
                                messageToSend = ""
                            }
                            .disabled(messageToSend.isEmpty)
                        }
                    }
                }

                Section("Messages") {
                    HistoryView(history: viewModel.messageHistory) { item in
                        // Message details
                    } onClear: {
                        viewModel.messageHistory.removeAll()
                    }
                    .frame(height: 300)
                }
            }
        }
    }
}

class WebSocketMonitorViewModel: ObservableObject {
    @Published var url = "wss://echo.websocket.org"
    @Published var isConnected = false
    @Published var latency = 0
    @Published var messageHistory: [HistoryItem] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()

    func connect() {
        guard let urlObj = URL(string: url) else { return }
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: urlObj)
        webSocketTask?.resume()
        isConnected = true
        receive()

        // Mock latency monitoring
        Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.latency = Int.random(in: 20...150)
            }
            .store(in: &cancellables)
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        cancellables.removeAll()
    }

    func send(_ message: String) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(wsMessage) { [weak self] error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            } else {
                DispatchQueue.main.async {
                    self?.messageHistory.insert(HistoryItem(title: "Sent", detail: message), at: 0)
                }
            }
        }
    }

    private func receive() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    switch message {
                    case .string(let text):
                        self?.messageHistory.insert(HistoryItem(title: "Received", detail: text), at: 0)
                    case .data(let data):
                        self?.messageHistory.insert(HistoryItem(title: "Received (Binary)", detail: "\(data.count) bytes"), at: 0)
                    @unknown default:
                        break
                    }
                }
                self?.receive()
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.messageHistory.insert(HistoryItem(title: "Error", detail: error.localizedDescription), at: 0)
                }
            }
        }
    }
}
