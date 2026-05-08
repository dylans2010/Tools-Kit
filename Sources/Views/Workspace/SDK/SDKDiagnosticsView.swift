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
                SDKModernCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        healthRow(title: "Connector Reachability", status: bgEngine.systemHealth.connectorReachability)
                        healthRow(title: "Plugin Sandbox", status: bgEngine.systemHealth.pluginSandboxStatus)
                        healthRow(title: "Data Store Health", status: bgEngine.systemHealth.coreDataHealth)

                        Divider().opacity(0.3)

                        HStack {
                            Text("Last Check").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(bgEngine.systemHealth.lastCheck.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }

                        Button {
                            bgEngine.startHealthCheckLoop()
                        } label: {
                            Label("Run Health Audit", systemImage: "arrow.clockwise.circle.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                SDKSectionHeader("System Health", subtitle: "Core service reachability and integrity", systemImage: "heart.text.square.fill")
            }

            Section {
                let metrics = telemetry.getMetrics()
                HStack(spacing: 12) {
                    SDKStatPill(label: "Latency", value: String(format: "%.0fms", metrics.averageDurationMs), color: metrics.averageDurationMs < 500 ? .sdkSuccess : .sdkWarning)
                    SDKStatPill(label: "Traces", value: "\(metrics.totalTraces)", color: .blue)
                    let rate = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100 : 100
                    SDKStatPill(label: "Health", value: "\(Int(rate))%", color: rate > 90 ? .sdkSuccess : .sdkError)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } header: {
                SDKSectionHeader("Performance", subtitle: "Real time execution metrics", systemImage: "chart.bar.fill")
            }

            Section {
                ForEach(SDKScope.allCases, id: \.self) { scope in
                    HStack {
                        Label(String(describing: scope).capitalized, systemImage: "cylinder.split.1x2")
                            .font(.subheadline)
                        Spacer()
                        let itemCount = cachedItemCount(for: scope)
                        SDKStatusPill(
                            itemCount > 0 ? "\(itemCount) Items" : "Empty",
                            color: itemCount > 0 ? .sdkSuccess : .secondary,
                            isCapsule: false
                        )
                    }
                }
            } header: {
                SDKSectionHeader("Data Sync", subtitle: "Storage utilization per scope", systemImage: "arrow.triangle.2.circlepath")
            }

            Section {
                if pluginManager.plugins.isEmpty {
                    ContentUnavailableView("No Plugins", systemImage: "puzzlepiece", description: Text("No plugins installed in this project."))
                } else {
                    ForEach(pluginManager.plugins) { plugin in
                        HStack {
                            Label(plugin.name, systemImage: "puzzlepiece.extension.fill")
                                .font(.subheadline)
                            Spacer()
                            SDKStatusPill(
                                plugin.isEnabled ? "Active" : "Disabled",
                                systemImage: plugin.isEnabled ? "checkmark.shield.fill" : "xmark.shield.fill",
                                color: plugin.isEnabled ? .sdkSuccess : .sdkWarning
                            )
                        }
                    }
                }
            } header: {
                SDKSectionHeader("Plugin Integrity", subtitle: "Sandbox and permission status", systemImage: "shield.fill")
            }

            Section {
                if connectorManager.connectors.isEmpty {
                    ContentUnavailableView("No Connectors", systemImage: "cable.connector", description: Text("No external links registered."))
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        HStack {
                            Label(connector.name, systemImage: "link")
                                .font(.subheadline)
                            Spacer()
                            SDKStatusPill(connector.status.rawValue, color: connectorStatusColor(connector.status))
                        }
                    }
                }
            } header: {
                SDKSectionHeader("Connector Status", subtitle: "External API connectivity", systemImage: "network")
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
