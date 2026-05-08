import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared

    var body: some View {
        List {
            Section {
                healthRow(title: "Connector Reachability", status: bgEngine.systemHealth.connectorReachability)
                healthRow(title: "Plugin Sandbox", status: bgEngine.systemHealth.pluginSandboxStatus)
                healthRow(title: "Data Store Health", status: bgEngine.systemHealth.coreDataHealth)

                HStack {
                    Text("Last Check")
                    Spacer()
                    Text(bgEngine.systemHealth.lastCheck.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.secondary)
                }

                Button("Run Health Check Now") {
                    bgEngine.startHealthCheckLoop()
                }
                .font(.caption)
            } header: {
                Text("System Health")
            }

            Section {
                ForEach(SDKScope.allCases, id: \.self) { scope in
                    HStack {
                        Text(String(describing: scope).capitalized)
                        Spacer()
                        let itemCount = cachedItemCount(for: scope)
                        Text(itemCount > 0 ? "\(itemCount) Items" : "Empty")
                            .font(.caption)
                            .foregroundStyle(itemCount > 0 ? .green : .secondary)
                    }
                }
            } header: {
                Text("Data Sync")
            }

            Section {
                let metrics = telemetry.getMetrics()
                HStack {
                    Text("Avg Latency")
                    Spacer()
                    Text("\(String(format: "%.0f", metrics.averageDurationMs))ms")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(metrics.averageDurationMs < 500 ? .green : .orange)
                }
                HStack {
                    Text("Total Traces")
                    Spacer()
                    Text("\(metrics.totalTraces)").font(.caption)
                }
                HStack {
                    Text("Success Rate")
                    Spacer()
                    let rate = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100 : 100
                    Text("\(String(format: "%.0f", rate))%")
                        .font(.caption)
                        .foregroundStyle(rate > 90 ? .green : .red)
                }
                HStack {
                    Text("Active Traces")
                    Spacer()
                    Text("\(metrics.activeTraces)").font(.caption)
                }
            } header: {
                Text("Performance Metrics")
            }

            Section {
                if pluginManager.plugins.isEmpty {
                    Text("No Plugins Installed").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(pluginManager.plugins) { plugin in
                        HStack {
                            Text(plugin.name)
                            Spacer()
                            Image(systemName: plugin.isEnabled ? "checkmark.shield.fill" : "xmark.shield.fill")
                                .foregroundStyle(plugin.isEnabled ? .green : .orange)
                            Text(plugin.isEnabled ? "Active" : "Disabled")
                                .font(.caption)
                                .foregroundStyle(plugin.isEnabled ? .green : .orange)
                        }
                    }
                }
            } header: {
                Text("Plugin Integrity")
            }

            Section {
                if connectorManager.connectors.isEmpty {
                    Text("No Connectors Registered").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        HStack {
                            Text(connector.name)
                            Spacer()
                            Circle()
                                .fill(connectorStatusColor(connector.status))
                                .frame(width: 8, height: 8)
                            Text(connector.status.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Connector Status")
            }
        }
        .navigationTitle("Diagnostics")
        .onAppear {
            bgEngine.startHealthCheckLoop()
        }
    }

    private func healthRow(title: String, status: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(status ? .green : .red)
        }
    }

    private func cachedItemCount(for scope: SDKScope) -> Int {
        let cache = SDKDataEngine.shared.cacheSnapshot()
        return cache[scope] ?? 0
    }

    private func connectorStatusColor(_ status: ConnectorStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .error: return .red
        case .disconnected: return .gray
        }
    }
}
