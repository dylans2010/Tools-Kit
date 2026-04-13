import SwiftUI

struct WebSocketInspectorTool: Tool {
    let name = "WebSocket Inspector"
    let icon = "antenna.radiowaves.left.and.right"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Connect to WebSocket endpoints, log messages, and measure connection stability"
    let requiresAPI = false
    var view: AnyView { AnyView(WebSocketInspectorView()) }
}

struct WebSocketInspectorView: View {
    @StateObject private var backend = WebSocketInspectorBackend()

    var body: some View {
        ToolDetailView(tool: WebSocketInspectorTool()) {
            VStack(spacing: 16) {
                connectionSection
                if backend.isConnected { statsBar }
                sendSection
                messagesSection
            }
        }
        .navigationTitle("WebSocket Inspector")
        .onDisappear { if backend.isConnected { backend.disconnect() } }
    }

    private var connectionSection: some View {
        ToolInputSection("Connection") {
            VStack(spacing: 10) {
                TextField("wss://echo.websocket.org", text: $backend.urlString)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .disabled(backend.isConnected)
                HStack {
                    Button(backend.isConnected ? "Disconnect" : "Connect") {
                        backend.isConnected ? backend.disconnect() : backend.connect()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(backend.isConnected ? .red : .green)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(backend.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(backend.statusMessage).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var statsBar: some View {
        HStack(spacing: 12) {
            Label(String(format: "%.0f ms Ping", backend.pingMs), systemImage: "speedometer")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Label(backend.connectionAge, systemImage: "timer")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var sendSection: some View {
        ToolInputSection("Send Message") {
            HStack {
                TextField("Message To Send", text: $backend.sendText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!backend.isConnected)
                Button(action: backend.send) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(!backend.isConnected || backend.sendText.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var messagesSection: some View {
        ToolInputSection("Message Log") {
            HStack {
                Spacer()
                Button("Clear") { backend.clearLog() }.font(.caption)
            }
            .padding(.horizontal)

            if backend.messages.isEmpty {
                Text("No Messages Yet").font(.caption).foregroundColor(.secondary).padding()
            } else {
                ForEach(backend.messages) { msg in
                    messageRow(msg)
                    Divider()
                }
            }
        }
    }

    private func messageRow(_ msg: WebSocketMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconFor(msg.direction))
                .foregroundColor(colorFor(msg.direction))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(msg.content)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                Text(msg.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func iconFor(_ dir: WebSocketMessage.Direction) -> String {
        switch dir {
        case .sent: return "arrow.up.circle"
        case .received: return "arrow.down.circle"
        case .system: return "info.circle"
        }
    }

    private func colorFor(_ dir: WebSocketMessage.Direction) -> Color {
        switch dir {
        case .sent: return .blue
        case .received: return .green
        case .system: return .orange
        }
    }
}
