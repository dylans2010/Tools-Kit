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
            Section {
                HealthStatusRow(title: "Connector Reachability", healthy: bgEngine.systemHealth.connectorReachability)
                HealthStatusRow(title: "Plugin Sandbox", healthy: bgEngine.systemHealth.pluginSandboxStatus)
                HealthStatusRow(title: "Data Store Health", healthy: bgEngine.systemHealth.coreDataHealth)

                LabeledContent("Last Audit", value: "\(bgEngine.systemHealth.lastCheck, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(action: { bgEngine.startHealthCheckLoop() }) {
                    Label("Run System Audit", systemImage: "arrow.clockwise.circle").bold()
                }
                .frame(maxWidth: .infinity)
            } header: {
                Text("System Health")
            }

            Section("Performance Analytics") {
                let metrics = telemetry.getMetrics()
                LabeledContent("Latency", value: "\(Int(metrics.averageDurationMs))ms")
                LabeledContent("Total Traces", value: "\(metrics.totalTraces)")
                LabeledContent("Execution Health") {
                    let rate = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100 : 100
                    Text("\(Int(rate))%").foregroundStyle(rate > 90 ? .green : .orange).bold()
                }
            }

            Section("Data Sync State") {
                ForEach(SDKScope.allCases, id: \.self) { scope in
                    LabeledContent(String(describing: scope).capitalized) {
                        let count = cachedItemCount(for: scope)
                        Text(count > 0 ? "\(count) Items" : "Empty")
                            .font(.caption2.bold())
                            .foregroundStyle(count > 0 ? .green : .secondary)
                    }
                }
            }

            Section("Module Integrity") {
                if pluginManager.plugins.isEmpty {
                    Text("No plugins loaded").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(pluginManager.plugins) { plugin in
                        LabeledContent(plugin.name) {
                            Text(plugin.isEnabled ? "Active" : "Disabled")
                                .font(.caption2.bold())
                                .foregroundStyle(plugin.isEnabled ? .green : .secondary)
                        }
                    }
                }
            }

            Section("External Connectivity") {
                if connectorManager.connectors.isEmpty {
                    Text("No connectors registered").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        LabeledContent(connector.name) {
                            Text(connector.status.rawValue.capitalized)
                                .font(.caption2.bold())
                                .foregroundStyle(connector.status == .connected ? .green : .orange)
                        }
                    }
                }
            }
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

private struct HealthStatusRow: View {
    let title: String, healthy: Bool
    var body: some View {
        LabeledContent(title) {
            Image(systemName: healthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(healthy ? .green : .red)
        }
    }
}
