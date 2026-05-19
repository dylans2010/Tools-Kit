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
        List {
            Section("Socket Handshake") {
                VStack(spacing: 12) {
                    HStack {
                        TextField("wss://api.endpoint.com", text: $viewModel.url)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button(viewModel.isConnected ? "Close" : "Open") {
                            viewModel.isConnected ? viewModel.disconnect() : viewModel.connect()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.isConnected ? .red : .blue)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 20) {
                        SocketMetric(label: "Status", value: viewModel.isConnected ? "ACTIVE" : "IDLE", color: viewModel.isConnected ? .green : .secondary)
                        SocketMetric(label: "Latency", value: "\(viewModel.latency)ms", color: .orange)
                        SocketMetric(label: "Frames", value: "\(viewModel.messageHistory.count)", color: .blue)
                    }
                }
                .padding(.vertical, 8)
            }

            if viewModel.isConnected {
                Section("Outbound Frame") {
                    HStack {
                        TextField("Type message...", text: $messageToSend)
                            .font(.subheadline)

                        Button {
                            viewModel.send(messageToSend)
                            messageToSend = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .disabled(messageToSend.isEmpty)
                    }
                }
            }

            Section("Frame History") {
                if viewModel.messageHistory.isEmpty {
                    ContentUnavailableView("No Frames", systemImage: "bolt.horizontal.circle", description: Text("Connection traffic will appear here."))
                } else {
                    ForEach(viewModel.messageHistory) { item in
                        FrameRow(item: item)
                    }
                }
            }

            Section {
                Button(role: .destructive) { viewModel.messageHistory.removeAll() } label: {
                    Label("Clear Log", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Socket Lab")
    }
}

struct SocketMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FrameRow: View {
    let item: HistoryItem
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.title == "Sent" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(item.title == "Sent" ? .blue : .green)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.detail)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(5)
                Text(item.timestamp, style: .time)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
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

#Preview {
    WebSocketMonitorView()
}
