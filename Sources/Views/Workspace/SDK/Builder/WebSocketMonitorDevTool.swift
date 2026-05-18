import SwiftUI

struct WebSocketMonitorDevTool: DevTool {
    let id = "websocket-monitor"
    let name = "WebSocket Monitor"
    let category = DevToolCategory.networking
    let icon = "bolt.horizontal"
    let description = "Monitor WebSocket connections"

    func render() -> some View {
        WebSocketMonitorView()
    }
}

struct WebSocketMonitorView: View {
    @StateObject private var viewModel = WebSocketMonitorViewModel()

    var body: some View {
        Form {
            Section("Connection") {
                TextField("wss://echo.websocket.org", text: $viewModel.urlString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                HStack {
                    Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                        if viewModel.isConnected {
                            viewModel.disconnect()
                        } else {
                            viewModel.connect()
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(viewModel.isConnected ? .green : .red)
                        .frame(width: 10, height: 10)
                }
            }

            Section("Messages") {
                TextField("Message to send", text: $viewModel.messageToSend)
                Button("Send") {
                    viewModel.send()
                }
                .disabled(!viewModel.isConnected || viewModel.messageToSend.isEmpty)

                Divider()

                ForEach(viewModel.messages.reversed(), id: \.id) { msg in
                    HStack {
                        Image(systemName: msg.isSent ? "arrow.up.circle" : "arrow.down.circle")
                            .foregroundStyle(msg.isSent ? .blue : .green)
                        Text(msg.text)
                            .font(.monospaced(.caption)())
                    }
                }
            }
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

struct WSMessage: Identifiable {
    let id = UUID()
    let text: String
    let isSent: Bool
}

class WebSocketMonitorViewModel: ObservableObject {
    @Published var urlString = "wss://echo.websocket.org"
    @Published var isConnected = false
    @Published var messages: [WSMessage] = []
    @Published var messageToSend = ""

    private var webSocketTask: URLSessionWebSocketTask?

    func connect() {
        guard let url = URL(string: urlString) else { return }
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    func send() {
        let msg = messageToSend
        webSocketTask?.send(.string(msg)) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.messages.append(WSMessage(text: msg, isSent: true))
                    self.messageToSend = ""
                }
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    switch message {
                    case .string(let text):
                        self?.messages.append(WSMessage(text: text, isSent: false))
                    case .data(let data):
                        self?.messages.append(WSMessage(text: "Binary data: \(data.count) bytes", isSent: false))
                    @unknown default:
                        break
                    }
                }
                self?.receiveMessage()
            case .failure:
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }
    }
}
