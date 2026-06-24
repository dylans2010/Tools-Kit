import SwiftUI

struct OpenClawMainView: View {
    @State private var viewModel = OpenClawMainViewModel.shared
    @State private var showingPairing = false

    var body: some View {
        List {
            Section("Paired Devices") {
                if viewModel.devices.isEmpty {
                    Text("No devices paired")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.devices) { device in
                        NavigationLink {
                            OpenClawDeviceDetailView(device: device)
                        } label: {
                            HStack {
                                Image(systemName: "macmini")
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                    Text(device.host).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Button {
                    showingPairing = true
                } label: {
                    Label("Pair New Device", systemImage: "plus")
                }
            }

            Section("Global System") {
                NavigationLink {
                    OpenClawLogsView(logs: viewModel.logs)
                } label: {
                    Label("Connection Logs", systemImage: "terminal")
                }

                NavigationLink {
                    OpenClawSettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("OpenClaw")
        .sheet(isPresented: $showingPairing) {
            OpenClawPairView()
                .onDisappear { viewModel.refreshDevices() }
        }
    }
}

struct OpenClawDeviceListView: View {
    let devices: [OpenClawDevice]

    var body: some View {
        List(devices) { device in
            HStack {
                Image(systemName: "macmini")
                VStack(alignment: .leading) {
                    Text(device.name)
                    Text(device.host).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Paired Devices")
    }
}

struct OpenClawDeviceDetailView: View {
    let device: OpenClawDevice
    @State private var viewModel = OpenClawMainViewModel.shared

    var body: some View {
        List {
            Section("Connection") {
                HStack {
                    Circle()
                        .fill(viewModel.isConnected ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    Spacer()
                    if viewModel.isConnected {
                        Button("Disconnect") { Task { await viewModel.disconnect() } }
                    } else {
                        Button("Connect") { Task { await viewModel.connect(to: device) } }
                    }
                }
            }

            if viewModel.isConnected, let service = viewModel.gatewayService {
                Section("Tools") {
                    NavigationLink {
                        OpenClawAgentView(service: service)
                    } label: {
                        Label("AI Agent", systemImage: "sparkles")
                    }
                }
            }

            Section("Info") {
                LabeledContent("Name", value: device.name)
                LabeledContent("Host", value: device.host)
                LabeledContent("Port", value: "\(device.port)")
                if let last = device.lastConnected {
                    LabeledContent("Last Connected", value: last.formatted())
                }
            }

            Section("Actions") {
                Button {
                    Task { await viewModel.identify() }
                } label: {
                    Label("Identify Device", systemImage: "lightbulb")
                }

                Button(role: .destructive) {
                    Task { await viewModel.restart() }
                } label: {
                    Label("Restart Gateway", systemImage: "power")
                }
            }
        }
        .navigationTitle(device.name)
    }
}

struct OpenClawLogsView: View {
    let logs: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(logs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Logs")
        .background(Color(.systemGroupedBackground))
    }
}

struct OpenClawSettingsView: View {
    @State private var autoConnect = true
    @State private var viewModel = OpenClawMainViewModel.shared

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Auto-connect to last device", isOn: $autoConnect)
            }

            Section("Security") {
                Button("Clear All Tokens", role: .destructive) {
                    viewModel.clearAllTokens()
                }
            }
        }
        .navigationTitle("OpenClaw Settings")
    }
}
