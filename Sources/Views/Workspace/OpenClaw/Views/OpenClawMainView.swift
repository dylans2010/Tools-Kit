import SwiftUI

struct OpenClawMainView: View {
    @StateObject private var viewModel = OpenClawMainViewModel()
    @State private var showingPair = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                statusSection
                actionsSection
                deviceSection
            }
            .navigationTitle("OpenClaw")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingPair) {
                OpenClawPairView()
            }
            .sheet(isPresented: $showingSettings) {
                OpenClawSettingsView()
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Text("Connection")
                Spacer()
                ConnectionBadge(status: viewModel.connectionStatus, isConnecting: viewModel.isConnecting)
            }

            if let error = viewModel.lastError {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        viewModel.connect()
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }

            HStack {
                Text("Latency")
                Spacer()
                Text(viewModel.latency)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            if viewModel.connectionStatus == "Connected" {
                Button(role: .destructive) {
                    viewModel.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "bolt.slash.fill")
                }
            } else {
                Button {
                    viewModel.connect()
                } label: {
                    HStack {
                        Label("Connect", systemImage: "bolt.fill")
                        if viewModel.isConnecting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isConnecting || viewModel.activeDeviceName == "None")
            }
        }
    }

    private var deviceSection: some View {
        Section("Active Device") {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.activeDeviceName)
                        .font(.headline)
                    if viewModel.activeDeviceName == "None" {
                        Text("No gateway paired")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Switch") {
                    showingPair = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

struct ConnectionBadge: View {
    let status: String
    let isConnecting: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isConnecting {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            Text(status)
                .font(.subheadline.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case "Connected": return .green
        case "Error": return .red
        case "Disconnected": return .secondary
        default: return .orange
        }
    }
}
