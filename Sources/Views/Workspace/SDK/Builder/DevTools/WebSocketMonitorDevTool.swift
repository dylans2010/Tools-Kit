import SwiftUI

struct WebSocketMonitorTool: DevTool {
    let id = UUID()
    let name = "WebSocket Monitor"
    let category: DevToolCategory = .networking
    let icon = "bolt.horizontal"
    let description = "Connect to WebSocket endpoints and monitor messages"
    func render() -> some View { WebSocketMonitorDevToolView() }
}

struct WebSocketMonitorDevToolView: View {
    @State private var urlString = "wss://echo.websocket.org"
    @State private var messageToSend = "Hello, WebSocket!"
    @State private var messages: [(String, Bool, String)] = []
    @State private var isConnected = false
    @State private var wsTask: URLSessionWebSocketTask?
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("Connection") {
                TextField("WebSocket URL", text: $urlString)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                HStack {
                    Button(isConnected ? "Disconnect" : "Connect") {
                        isConnected ? disconnect() : connect()
                    }
                    Spacer()
                    Circle().fill(isConnected ? Color.green : Color.red).frame(width: 10, height: 10)
                    Text(isConnected ? "Connected" : "Disconnected").font(.caption)
                }
            }
            if isConnected {
                Section("Send") {
                    HStack {
                        TextField("Message", text: $messageToSend)
                            .font(.system(.body, design: .monospaced))
                        Button("Send") { sendMessage() }
                            .disabled(messageToSend.isEmpty)
                    }
                }
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            Section("Messages (\(messages.count))") {
                ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                    HStack(alignment: .top) {
                        Image(systemName: msg.1 ? "arrow.up.circle" : "arrow.down.circle")
                            .foregroundStyle(msg.1 ? .blue : .green)
                            .font(.caption)
                        VStack(alignment: .leading) {
                            Text(msg.0).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                            Text(msg.2).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("WebSocket Monitor")
    }

    private func connect() {
        guard let url = URL(string: urlString) else { errorMsg = "Invalid URL"; return }
        errorMsg = nil
        wsTask = URLSession.shared.webSocketTask(with: url)
        wsTask?.resume()
        isConnected = true
        addMessage("Connected to \(urlString)", sent: false)
        receiveMessage()
    }

    private func disconnect() {
        wsTask?.cancel(with: .normalClosure, reason: nil)
        wsTask = nil
        isConnected = false
        addMessage("Disconnected", sent: false)
    }

    private func sendMessage() {
        let msg = messageToSend
        wsTask?.send(.string(msg)) { error in
            DispatchQueue.main.async {
                if let error { errorMsg = error.localizedDescription; return }
                addMessage(msg, sent: true)
            }
        }
    }

    private func receiveMessage() {
        wsTask?.receive { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text): addMessage(text, sent: false)
                    case .data(let data): addMessage("Binary: \(data.count) bytes", sent: false)
                    @unknown default: break
                    }
                    receiveMessage()
                case .failure(let error):
                    if isConnected { errorMsg = error.localizedDescription; isConnected = false }
                }
            }
        }
    }

    private func addMessage(_ text: String, sent: Bool) {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"
        messages.insert((text, sent, f.string(from: Date())), at: 0)
    }
}
