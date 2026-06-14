import SwiftUI

struct BridgeHomeView: View {
    @StateObject private var tkClient = TKBridgeClient.shared
    @StateObject private var connectionManager = BridgeConnectionManager.shared
    @StateObject private var sessionManager = BridgeSessionManager.shared
    @State private var showingPairing = false
    @State private var showingSettings = false

    var body: some View {
        List {
            Section {
                tkConnectionStatusCard
            } header: {
                Text("Distributed Connection (TKBridge)")
            }

            Section {
                connectionStatusCard
            } header: {
                Text("Legacy Connection Status")
            }

            Section {
                if sessionManager.pairedDevices.isEmpty {
                    Text("No paired devices found")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(sessionManager.pairedDevices) { device in
                        DeviceRow(device: device, isActive: connectionManager.activeDevice?.id == device.id)
                            .onTapGesture {
                                connectionManager.selectDevice(device)
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            sessionManager.removeDevice(sessionManager.pairedDevices[index].id)
                        }
                    }
                }
            } header: {
                Text("Saved Connections")
            }

            Section {
                Button {
                    showingPairing = true
                } label: {
                    Label("Pair New Device", systemImage: "plus.circle.fill")
                }

                NavigationLink(destination: BridgeChatView()) {
                    Label("Open Chat Session", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .disabled(connectionManager.connectionState != .connected)

                Button {
                    showingSettings = true
                } label: {
                    Label("Bridge Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .navigationTitle("Device Bridge")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if connectionManager.connectionState == .disconnected && connectionManager.activeDevice != nil {
                    Button("Connect") {
                        connectionManager.connect()
                    }
                } else if connectionManager.connectionState == .connected {
                    Button("Disconnect", role: .destructive) {
                        connectionManager.disconnect()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPairing) {
            NavigationStack {
                BridgePairingView()
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                BridgeSettingsView()
            }
        }
    }

    private var tkConnectionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(tkStatusColor)
                    .frame(width: 12, height: 12)

                Text(tkStatusText)
                    .font(.headline)

                Spacer()
            }

            if case .connected(let device) = tkClient.state {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                        Text(device.name)
                        Text("•")
                        Text(device.os)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hostname: \(device.hostname)")
                        Text("IP: \(device.ip)")
                        Text("OS Version: \(device.version)")
                        Text("Architecture: \(device.architecture)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else if case .failed(let message) = tkClient.state {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if tkClient.state == .disconnected {
                Button("Install tkbridge host") {
                    // Logic to show install instructions
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var tkStatusColor: Color {
        switch tkClient.state {
        case .connected: return .green
        case .discovering, .pairing, .reconnecting: return .orange
        case .failed: return .red
        case .disconnected: return .gray
        case .hostFound: return .blue
        }
    }

    private var tkStatusText: String {
        switch tkClient.state {
        case .connected: return "Connected"
        case .discovering: return "Discovering..."
        case .pairing: return "Pairing..."
        case .reconnecting: return "Reconnecting..."
        case .failed: return "Connection Failed"
        case .disconnected: return "Disconnected"
        case .hostFound(let ip): return "Host Found: \(ip)"
        }
    }

    private var connectionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(connectionManager.connectionState.color)
                    .frame(width: 12, height: 12)

                Text(connectionManager.connectionState.description)
                    .font(.headline)

                Spacer()

                if connectionManager.connectionState == .connected {
                    Text("\(connectionManager.currentLatency)ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let device = connectionManager.activeDevice {
                HStack {
                    Image(systemName: device.platform.iconName)
                    Text(device.name)
                    Text("•")
                    Text(device.platform.rawValue)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Text("Host: \(device.hostURL.absoluteString):\(device.port)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if case .error(let error) = connectionManager.connectionState {
                NavigationLink(destination: BridgeTroubleshootingView()) {
                    Label("Troubleshoot", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DeviceRow: View {
    let device: BridgeDevice
    let isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: device.platform.iconName)
                .foregroundColor(isActive ? .blue : .primary)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(isActive ? .bold : .regular)
                if let last = device.lastConnected {
                    Text("Last connected: \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
    }
}
