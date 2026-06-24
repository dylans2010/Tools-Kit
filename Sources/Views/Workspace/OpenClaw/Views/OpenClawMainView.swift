import SwiftUI

struct OpenClawMainView: View {
    @StateObject private var viewModel = OpenClawMainViewModel()
    @State private var showingPairing = false

    var body: some View {
        List {
            Section("Gateway Connection") {
                HStack {
                    VStack(alignment: .leading) {
                        Text(viewModel.activeDeviceName)
                            .font(.headline)
                        Text(viewModel.connectionStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if viewModel.connectionStatus == "Connected" {
                        Button("Disconnect", role: .destructive) {
                            viewModel.disconnect()
                        }
                    } else {
                        Button("Connect") {
                            viewModel.connect()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            Section("Live Metrics") {
                HStack {
                    OpenClawMetricTile(title: "Latency", value: viewModel.latency, icon: "timer")
                    OpenClawMetricTile(title: "Quality", value: "98%", icon: "antenna.radiowaves.left.and.right")
                }
            }

            Section("System") {
                NavigationLink {
                    OpenClawChatView()
                } label: {
                    Label("AI Controller", systemImage: "sparkles")
                }

                NavigationLink {
                    OpenClawDeviceListView()
                } label: {
                    Label("Manage Devices", systemImage: "macpro.gen3")
                }
            }

            Section("Diagnostics") {
                NavigationLink {
                    OpenClawLogsView()
                } label: {
                    Label("System Logs", systemImage: "terminal")
                }
            }
        }
        .navigationTitle("OpenClaw")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingPairing = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingPairing) {
            OpenClawPairView()
        }
    }
}

struct OpenClawMetricTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
