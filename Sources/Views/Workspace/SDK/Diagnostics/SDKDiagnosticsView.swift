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

    private var systemHealthSection: some View {
        Section("System Health") {
            LabeledContent("Connector Reachability") {
                Image(systemName: bgEngine.systemHealth.connectorReachability ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(bgEngine.systemHealth.connectorReachability ? Color.green : Color.red)
            }
            LabeledContent("Plugin Sandbox") {
                Image(systemName: bgEngine.systemHealth.pluginSandboxStatus ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(bgEngine.systemHealth.pluginSandboxStatus ? Color.green : Color.red)
            }
            LabeledContent("Data Store Health") {
                Image(systemName: bgEngine.systemHealth.coreDataHealth ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(bgEngine.systemHealth.coreDataHealth ? Color.green : Color.red)
            }
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
                let count = SDKDataEngine.shared.cacheSnapshot()[scope] ?? 0
                LabeledContent(String(describing: scope).capitalized) {
                    Text(count > 0 ? "\(count) Items" : "Empty")
                        .font(.caption2.bold())
                        .foregroundStyle(count > 0 ? Color.green : Color.secondary)
                }
            }
        }
    }

    private var moduleIntegritySection: some View {
        Section("Module Integrity") {
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
        }
    }

    private var connectivitySection: some View {
        Section("External Connectivity") {
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
        }
    }
}
