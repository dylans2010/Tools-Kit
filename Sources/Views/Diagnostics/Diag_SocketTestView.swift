import SwiftUI
import Network

struct Diag_SocketTestView: View {
    @State private var host: String = "apple.com"
    @State private var port: String = "443"
    @State private var connectionStatus: ConnectionState = .idle
    @State private var connectionTime: TimeInterval = 0
    @State private var tlsVersion: String = "N/A"
    @State private var localEndpoint: String = "N/A"
    @State private var remoteEndpoint: String = "N/A"
    @State private var connectionHistory: [ConnectionEntry] = []
    private let maxHistory = 20

    enum ConnectionState {
        case idle, connecting, connected, failed, cancelled
        var label: String {
            switch self {
            case .idle: return "Idle"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
        var color: Color {
            switch self {
            case .idle: return .secondary
            case .connecting: return .blue
            case .connected: return .green
            case .failed: return .red
            case .cancelled: return .orange
            }
        }
    }

    struct ConnectionEntry: Identifiable {
        let id = UUID()
        let host: String
        let port: String
        let success: Bool
        let time: TimeInterval
        let timestamp: Date
    }

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Host", text: $host)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("Port", text: $port)
                    .keyboardType(.numberPad)
            }

            Section("Status") {
                HStack {
                    Circle()
                        .fill(connectionStatus.color)
                        .frame(width: 10, height: 10)
                    Text(connectionStatus.label)
                        .font(.headline)
                    Spacer()
                    if connectionStatus == .connected {
                        Text(String(format: "%.0f ms", connectionTime * 1000))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if connectionStatus == .connected {
                    LabeledContent("Connection Time") {
                        Text(String(format: "%.1f ms", connectionTime * 1000))
                            .monospacedDigit()
                    }
                    LabeledContent("TLS") { Text(tlsVersion) }
                    LabeledContent("Local") { Text(localEndpoint).font(.caption) }
                    LabeledContent("Remote") { Text(remoteEndpoint).font(.caption) }
                }
            }

            Section {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                        Text("Test Connection")
                    }
                }
                .disabled(host.isEmpty || port.isEmpty || connectionStatus == .connecting)

                HStack(spacing: 8) {
                    Button("TCP :80") {
                        port = "80"
                        testConnection()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    Button("TLS :443") {
                        port = "443"
                        testConnection()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    Button("SSH :22") {
                        port = "22"
                        testConnection()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }

            if !connectionHistory.isEmpty {
                Section("History") {
                    ForEach(connectionHistory) { entry in
                        HStack {
                            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(entry.success ? .green : .red)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(entry.host):\(entry.port)")
                                    .font(.caption)
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(String(format: "%.0f ms", entry.time * 1000))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Socket Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testConnection() {
        guard let portNum = UInt16(port) else { return }
        connectionStatus = .connecting
        let startTime = CFAbsoluteTimeGetCurrent()

        let params: NWParameters = portNum == 443 ? .tls : .tcp
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: portNum)!, using: params)

        connection.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.connectionTime = CFAbsoluteTimeGetCurrent() - startTime
                    self.connectionStatus = .connected
                    self.tlsVersion = portNum == 443 ? "TLS 1.2/1.3" : "N/A (plaintext)"
                    if let local = connection.currentPath?.localEndpoint {
                        self.localEndpoint = "\(local)"
                    }
                    if let remote = connection.currentPath?.remoteEndpoint {
                        self.remoteEndpoint = "\(remote)"
                    }
                    self.connectionHistory.insert(
                        ConnectionEntry(host: self.host, port: self.port, success: true, time: self.connectionTime, timestamp: Date()),
                        at: 0
                    )
                    if self.connectionHistory.count > self.maxHistory { self.connectionHistory.removeLast() }
                    connection.cancel()
                case .failed:
                    self.connectionTime = CFAbsoluteTimeGetCurrent() - startTime
                    self.connectionStatus = .failed
                    self.connectionHistory.insert(
                        ConnectionEntry(host: self.host, port: self.port, success: false, time: self.connectionTime, timestamp: Date()),
                        at: 0
                    )
                    if self.connectionHistory.count > self.maxHistory { self.connectionHistory.removeLast() }
                case .cancelled:
                    if self.connectionStatus == .connecting {
                        self.connectionStatus = .cancelled
                    }
                default:
                    break
                }
            }
        }
        connection.start(queue: .global(qos: .userInitiated))

        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            if connection.state != .ready && connection.state != .cancelled {
                connection.cancel()
                DispatchQueue.main.async { self.connectionStatus = .failed }
            }
        }
    }
}
