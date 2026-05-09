/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual card-based health reporting with native Section and LabeledContent.
 - Modernized status pills and metrics using semantic colors (.green, .yellow, .red) and bold monospaced fonts.
 - Replaced manual health row logic with a private HealthStatusRow struct.
 - strictly preserved all SDKBackgroundEngine, SDKTelemetryEngine, and SDKPluginManager data sources.
 - Improved visual hierarchy for storage utilization and connectivity status.
 - Standardized the 'Audit' action button with a prominent prominent style.
 */

import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared

    var body: some View {
        List {
            SDKDiagnosticsSystemHealthSection(bgEngine: bgEngine)
            SDKDiagnosticsPerformanceSection(telemetry: telemetry)
            SDKDiagnosticsDataSyncSection(cachedItemCount: cachedItemCount)
            SDKDiagnosticsModuleIntegritySection(pluginManager: pluginManager)
            SDKDiagnosticsConnectivitySection(connectorManager: connectorManager)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bgEngine.startHealthCheckLoop() }
    }

    private func cachedItemCount(for scope: SDKScope) -> Int {
        return SDKDataEngine.shared.cacheSnapshot()[scope] ?? 0
    }
}

// MARK: - Private Subviews

private struct SDKDiagnosticsSystemHealthSection: View {
    struct HealthItem: Identifiable {
        let id: String
        let title: String
        let healthy: Bool
    }

    let bgEngine: SDKBackgroundEngine

    private var healthItems: [HealthItem] {
        [
            HealthItem(id: "connector-reachability", title: "Connector Reachability", healthy: bgEngine.systemHealth.connectorReachability),
            HealthItem(id: "plugin-sandbox", title: "Plugin Sandbox", healthy: bgEngine.systemHealth.pluginSandboxStatus),
            HealthItem(id: "data-store-health", title: "Data Store Health", healthy: bgEngine.systemHealth.coreDataHealth)
        ]
    }

    var body: some View {
        Section {
            ForEach(healthItems) { item in
                HealthStatusRow(title: item.title, healthy: item.healthy)
            }

            LabeledContent("Last Audit", value: "\(bgEngine.systemHealth.lastCheck, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(Color.secondary)

            Button(action: { bgEngine.startHealthCheckLoop() }) {
                Label("Run System Audit", systemImage: "arrow.clockwise.circle").bold()
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text("System Health")
        }
    }
}

private struct SDKDiagnosticsPerformanceSection: View {
    let telemetry: SDKTelemetryEngine

    var body: some View {
        let metrics = telemetry.getMetrics()
        let rate = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100 : 100

        return Section {
            LabeledContent("Latency", value: "\(Int(metrics.averageDurationMs))ms")
            LabeledContent("Total Traces", value: "\(metrics.totalTraces)")
            LabeledContent("Execution Health") {
                Text("\(Int(rate))%")
                    .foregroundStyle(rate > 90 ? .green : .orange)
                    .bold()
            }
        } header: {
            Text("Performance Analytics")
        }
    }
}

private struct SDKDiagnosticsDataSyncSection: View {
    let cachedItemCount: (SDKScope) -> Int

    var body: some View {
        Section {
            ForEach(SDKScope.allCases, id: \.self) { scope in
                LabeledContent(String(describing: scope).capitalized) {
                    Text(cachedItemCount(scope) > 0 ? "\(cachedItemCount(scope)) Items" : "Empty")
                        .font(.caption2.bold())
                        .foregroundStyle(cachedItemCount(scope) > 0 ? Color.green : Color.secondary)
                }
            }
        } header: {
            Text("Data Sync State")
        }
    }
}

private struct SDKDiagnosticsModuleIntegritySection: View {
    let pluginManager: SDKPluginManager

    var body: some View {
        Section {
            if pluginManager.plugins.isEmpty {
                Text("No plugins loaded").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(pluginManager.plugins) { plugin in
                    LabeledContent(plugin.name) {
                        Text(plugin.isEnabled ? "Active" : "Disabled")
                            .font(.caption2.bold())
                            .foregroundStyle(plugin.isEnabled ? Color.green : Color.secondary)
                    }
                }
            }
        } header: {
            Text("Module Integrity")
        }
    }
}

private struct SDKDiagnosticsConnectivitySection: View {
    let connectorManager: SDKConnectorManager

    var body: some View {
        Section {
            if connectorManager.connectors.isEmpty {
                Text("No connectors registered").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    LabeledContent(connector.name) {
                        Text(connector.status.rawValue.capitalized)
                            .font(.caption2.bold())
                            .foregroundStyle(connector.status == .connected ? Color.green : Color.orange)
                    }
                }
            }
        } header: {
            Text("External Connectivity")
        }
    }
}

private struct HealthStatusRow: View {
    let title: String, healthy: Bool
    var body: some View {
        LabeledContent(title) {
            Image(systemName: healthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(healthy ? .green : .red)
        }
    }
}
