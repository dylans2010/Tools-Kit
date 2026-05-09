import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared

    var body: some View {
        List {
            Section("System Health") {
                ForEach(systemHealthRows) { row in
                    StatusRow(title: row.title, isHealthy: row.isHealthy)
                }

                LabeledContent("Last Audit") {
                    Text("\(bgEngine.systemHealth.lastCheck, style: .relative) ago")
                        .foregroundStyle(.secondary)
                }

                Button {
                    bgEngine.startHealthCheckLoop()
                } label: {
                    Label("Run System Audit", systemImage: "arrow.clockwise.circle")
                        .fontWeight(.semibold)
                }
            }

            Section("Performance Analytics") {
                LabeledContent("Latency") {
                    Text("\(performanceSummary.averageLatencyMs)ms")
                }

                LabeledContent("Total Traces") {
                    Text("\(performanceSummary.totalTraces)")
                }

                LabeledContent("Execution Health") {
                    Text("\(performanceSummary.successRatePercent)%")
                        .foregroundStyle(performanceSummary.successRateColor)
                        .fontWeight(.semibold)
                }
            }

            Section("Data Sync State") {
                ForEach(dataSyncRows) { row in
                    LabeledContent(row.name) {
                        Text(row.countText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(row.countColor)
                    }
                }
            }

            Section("Module Integrity") {
                if pluginRows.isEmpty {
                    Text("No plugins loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pluginRows) { row in
                        LabeledContent(row.name) {
                            Text(row.stateText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(row.stateColor)
                        }
                    }
                }
            }

            Section("External Connectivity") {
                if connectorRows.isEmpty {
                    Text("No connectors registered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(connectorRows) { row in
                        LabeledContent(row.name) {
                            Text(row.stateText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(row.stateColor)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            bgEngine.startHealthCheckLoop()
        }
    }

    private var systemHealthRows: [SystemHealthRowModel] {
        [
            SystemHealthRowModel(id: "connector-reachability", title: "Connector Reachability", isHealthy: bgEngine.systemHealth.connectorReachability),
            SystemHealthRowModel(id: "plugin-sandbox", title: "Plugin Sandbox", isHealthy: bgEngine.systemHealth.pluginSandboxStatus),
            SystemHealthRowModel(id: "data-store-health", title: "Data Store Health", isHealthy: bgEngine.systemHealth.coreDataHealth)
        ]
    }

    private var performanceSummary: PerformanceSummaryModel {
        let metrics = telemetry.getMetrics()
        let successRate: Double
        if metrics.totalTraces > 0 {
            successRate = (Double(metrics.successCount) / Double(metrics.totalTraces)) * 100
        } else {
            successRate = 100
        }

        return PerformanceSummaryModel(
            averageLatencyMs: Int(metrics.averageDurationMs),
            totalTraces: metrics.totalTraces,
            successRatePercent: Int(successRate.rounded()),
            successRateColor: successRate >= 90 ? .green : .orange
        )
    }

    private var dataSyncRows: [DataSyncRowModel] {
        SDKScope.allCases.map { scope in
            let count = SDKDataEngine.shared.cacheSnapshot()[scope] ?? 0
            return DataSyncRowModel(id: String(describing: scope), name: String(describing: scope).capitalized, count: count)
        }
    }

    private var pluginRows: [PluginRowModel] {
        pluginManager.plugins.map { plugin in
            PluginRowModel(id: plugin.id.uuidString, name: plugin.name, isEnabled: plugin.isEnabled)
        }
    }

    private var connectorRows: [ConnectorRowModel] {
        connectorManager.connectors.map { connector in
            ConnectorRowModel(
                id: connector.id.uuidString,
                name: connector.name,
                statusText: connector.status.rawValue.capitalized,
                isConnected: connector.status == .connected
            )
        }
    }
}

private struct SystemHealthRowModel: Identifiable {
    let id: String
    let title: String
    let isHealthy: Bool
}

private struct PerformanceSummaryModel {
    let averageLatencyMs: Int
    let totalTraces: Int
    let successRatePercent: Int
    let successRateColor: Color
}

private struct DataSyncRowModel: Identifiable {
    let id: String
    let name: String
    let count: Int

    var countText: String {
        count > 0 ? "\(count) Items" : "Empty"
    }

    var countColor: Color {
        count > 0 ? .green : .secondary
    }
}

private struct PluginRowModel: Identifiable {
    let id: String
    let name: String
    let isEnabled: Bool

    var stateText: String {
        isEnabled ? "Active" : "Disabled"
    }

    var stateColor: Color {
        isEnabled ? .green : .secondary
    }
}

private struct ConnectorRowModel: Identifiable {
    let id: String
    let name: String
    let statusText: String
    let isConnected: Bool

    var stateText: String {
        statusText
    }

    var stateColor: Color {
        isConnected ? .green : .orange
    }
}

private struct StatusRow: View {
    let title: String
    let isHealthy: Bool

    var body: some View {
        LabeledContent(title) {
            Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isHealthy ? .green : .red)
        }
    }
}
