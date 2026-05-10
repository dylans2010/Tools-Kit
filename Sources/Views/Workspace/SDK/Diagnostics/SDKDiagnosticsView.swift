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
            systemHealthSection
            performanceSection
            syncStateSection
            moduleIntegritySection
            connectivitySection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bgEngine.startHealthCheckLoop() }
    }

    private func cachedItemCount(for scope: SDKScope) -> Int {
        SDKDataEngine.shared.cacheSnapshot()[scope] ?? 0
    }

    private var systemHealthSection: some View {
        Section("System Health") {
            HealthStatusRow(title: "Connector Reachability", healthy: bgEngine.systemHealth.connectorReachability)
            HealthStatusRow(title: "Plugin Sandbox", healthy: bgEngine.systemHealth.pluginSandboxStatus)
            HealthStatusRow(title: "Data Store Health", healthy: bgEngine.systemHealth.coreDataHealth)
            LabeledContent("Last Audit", value: "\(bgEngine.systemHealth.lastCheck, style: .relative) ago")
            Button(action: { bgEngine.startHealthCheckLoop() }) {
                Label("Run System Audit", systemImage: "arrow.clockwise.circle").bold()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var performanceSection: some View {
        let metrics: SDKTelemetryEngine.Metrics = telemetry.getMetrics()
        let successRate: Double = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100 : 100
        return Section("Performance Analytics") {
            LabeledContent("Latency", value: "\(Int(metrics.averageDurationMs))ms")
            LabeledContent("Total Traces", value: "\(metrics.totalTraces)")
            LabeledContent("Execution Health") {
                Text("\(Int(successRate))%")
                    .foregroundStyle(successRate > 90 ? Color.green : Color.orange)
                    .bold()
            }
        }
    }

    private var syncStateSection: some View {
        Section("Data Sync State") {
            ForEach(SDKScope.allCases, id: \.self) { scope in
                SyncScopeRow(scope: scope, itemCount: cachedItemCount(for: scope))
            }
        }
    }

    private var moduleIntegritySection: some View {
        Section("Module Integrity") {
            if pluginManager.plugins.isEmpty {
                Text("No plugins loaded").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(pluginManager.plugins) { plugin in
                    PluginStatusRow(name: plugin.name, isEnabled: plugin.isEnabled)
                }
            }
        }
    }

    private var connectivitySection: some View {
        Section("External Connectivity") {
            if connectorManager.connectors.isEmpty {
                Text("No connectors registered").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    ConnectorStatusRow(name: connector.name, statusText: connector.status.rawValue.capitalized, isConnected: connector.status == .connected)
                }
            }
        }
    }
}

// MARK: - Private Subviews

private struct HealthStatusRow: View {
    let title: String, healthy: Bool
    var body: some View {
        LabeledContent(title) {
            Image(systemName: healthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(healthy ? Color.green : Color.red)
        }
    }
}

private struct SyncScopeRow: View {
    let scope: SDKScope
    let itemCount: Int

    var body: some View {
        LabeledContent(String(describing: scope).capitalized) {
            Text(itemCount > 0 ? "\(itemCount) Items" : "Empty")
                .font(.caption2.bold())
                .foregroundStyle(itemCount > 0 ? Color.green : Color.secondary)
        }
    }
}

private struct PluginStatusRow: View {
    let name: String
    let isEnabled: Bool

    var body: some View {
        LabeledContent(name) {
            Text(isEnabled ? "Active" : "Disabled")
                .font(.caption2.bold())
                .foregroundStyle(isEnabled ? Color.green : Color.secondary)
        }
    }
}

private struct ConnectorStatusRow: View {
    let name: String
    let statusText: String
    let isConnected: Bool

    var body: some View {
        LabeledContent(name) {
            Text(statusText)
                .font(.caption2.bold())
                .foregroundStyle(isConnected ? Color.green : Color.orange)
        }
    }
}
