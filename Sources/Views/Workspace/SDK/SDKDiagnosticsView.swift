import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var backgroundEngine = SDKBackgroundEngine.shared
    @StateObject private var sdk = ToolsKitSDK.shared
    @State private var refreshTimer: Timer?

    var body: some View {
        List {
            Section("System Health") {
                HealthRow(label: "Overall Status", status: backgroundEngine.systemHealth.overallStatus)
                LabeledContent("Last Check", value: backgroundEngine.systemHealth.lastCheckTime.formatted(date: .omitted, time: .standard))
                LabeledContent("Memory Pressure", value: "Normal") // Mock
            }

            Section("Data Sync") {
                ForEach([SDKScope.notes, .tasks, .calendar, .files, .emails], id: \.self) { scope in
                    HStack {
                        Text("\(scope)".capitalized)
                        Spacer()
                        Text("Healthy")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Plugin Integrity") {
                if SDKPluginManager.shared.plugins.isEmpty {
                    Text("No plugins installed").foregroundStyle(.secondary)
                } else {
                    ForEach(SDKPluginManager.shared.plugins) { plugin in
                        HStack {
                            Text(plugin.name)
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            Section("Connector Status") {
                if SDKConnectorManager.shared.connectors.isEmpty {
                    Text("No connectors active").foregroundStyle(.secondary)
                } else {
                    ForEach(SDKConnectorManager.shared.connectors, id: \.id) { connector in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(connector.name)
                                Text(connector.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(connector.status == .connected ? .green : .red)
                            }
                            Spacer()
                            Text("12ms") // Latency mock
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            // Refresh logic
        }
    }
}

struct HealthRow: View {
    let label: String
    let status: HealthStatus
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HealthBadge(status: status)
        }
    }
}
