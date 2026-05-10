import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared

    var body: some View {
        let snapshot = makeSnapshot()

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DiagnosticsHeaderView(lastAuditText: snapshot.lastAuditText) {
                    bgEngine.startHealthCheckLoop()
                }

                DiagnosticsStatusPanel(
                    title: "System Health",
                    rows: snapshot.healthRows,
                    emptyMessage: "No health metrics available"
                )

                TelemetryCard(
                    metrics: snapshot.telemetryMetrics,
                    successRateText: snapshot.successRateText,
                    successRateColor: snapshot.successRateColor
                )

                MetricsSummaryView(items: snapshot.summaryItems)

                DiagnosticsStatusPanel(
                    title: "Data Sync State",
                    rows: snapshot.syncRows,
                    emptyMessage: "No scope data available"
                )

                DiagnosticsStatusPanel(
                    title: "Module Integrity",
                    rows: snapshot.pluginRows,
                    emptyMessage: "No plugins loaded"
                )

                DiagnosticsStatusPanel(
                    title: "External Connectivity",
                    rows: snapshot.connectorRows,
                    emptyMessage: "No connectors registered"
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func makeSnapshot() -> DiagnosticsSnapshot {
        let health = bgEngine.systemHealth
        let telemetryMetrics: TelemetryMetrics = telemetry.getMetrics()
        let successRate = successRateValue(for: telemetryMetrics)
        let successRateText = percentageText(from: successRate)
        let successRateColor = successRate >= 90 ? Color.green : Color.orange

        let healthRows: [HealthMetricDisplay] = [
            HealthMetricDisplay(
                id: "health.connectorReachability",
                title: "Connector Reachability",
                value: health.connectorReachability ? "Reachable" : "Unavailable",
                indicator: HealthIndicator(
                    text: health.connectorReachability ? "Healthy" : "Degraded",
                    tint: health.connectorReachability ? .green : .red,
                    systemImage: health.connectorReachability ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            ),
            HealthMetricDisplay(
                id: "health.pluginSandboxStatus",
                title: "Plugin Sandbox",
                value: health.pluginSandboxStatus ? "Secured" : "Warning",
                indicator: HealthIndicator(
                    text: health.pluginSandboxStatus ? "Healthy" : "Degraded",
                    tint: health.pluginSandboxStatus ? .green : .red,
                    systemImage: health.pluginSandboxStatus ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            ),
            HealthMetricDisplay(
                id: "health.coreDataHealth",
                title: "Data Store Health",
                value: health.coreDataHealth ? "Operational" : "Unavailable",
                indicator: HealthIndicator(
                    text: health.coreDataHealth ? "Healthy" : "Degraded",
                    tint: health.coreDataHealth ? .green : .red,
                    systemImage: health.coreDataHealth ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            )
        ]

        let cacheSnapshot = SDKDataEngine.shared.cacheSnapshot()
        let syncRows: [HealthMetricDisplay] = SDKScope.allCases.map { scope in
            let count = cacheSnapshot[scope] ?? 0
            return HealthMetricDisplay(
                id: "sync.\(scope.cacheKey)",
                title: scopeTitle(scope),
                value: count > 0 ? "\(count) Items" : "Empty",
                indicator: HealthIndicator(
                    text: count > 0 ? "Synced" : "Idle",
                    tint: count > 0 ? .green : .secondary,
                    systemImage: count > 0 ? "checkmark.circle.fill" : "minus.circle.fill"
                )
            )
        }

        let pluginRows: [HealthMetricDisplay] = pluginManager.plugins.map { plugin in
            HealthMetricDisplay(
                id: "plugin.\(plugin.id.uuidString)",
                title: plugin.name,
                value: plugin.version,
                indicator: HealthIndicator(
                    text: plugin.isEnabled ? "Active" : "Disabled",
                    tint: plugin.isEnabled ? .green : .secondary,
                    systemImage: plugin.isEnabled ? "checkmark.circle.fill" : "minus.circle.fill"
                )
            )
        }

        let connectorRows: [HealthMetricDisplay] = connectorManager.connectors.map { connector in
            let isConnected = connector.status == .connected
            return HealthMetricDisplay(
                id: "connector.\(connector.id.uuidString)",
                title: connector.name,
                value: connector.status.rawValue.capitalized,
                indicator: HealthIndicator(
                    text: isConnected ? "Connected" : "Offline",
                    tint: isConnected ? .green : .orange,
                    systemImage: isConnected ? "checkmark.circle.fill" : "bolt.slash.fill"
                )
            )
        }

        let totalCachedItems = cacheSnapshot.values.reduce(0, +)
        let connectedConnectors = connectorManager.connectors.filter { $0.status == .connected }.count
        let enabledPlugins = pluginManager.plugins.filter(\.isEnabled).count

        let summaryItems: [SummaryMetric] = [
            SummaryMetric(id: "summary.cachedScopes", title: "Cached Scopes", value: "\(cacheSnapshot.count)"),
            SummaryMetric(id: "summary.cachedItems", title: "Cached Items", value: "\(totalCachedItems)"),
            SummaryMetric(id: "summary.enabledPlugins", title: "Enabled Plugins", value: "\(enabledPlugins)"),
            SummaryMetric(id: "summary.connectedConnectors", title: "Connected", value: "\(connectedConnectors)"),
            SummaryMetric(id: "summary.activeTraces", title: "Active Traces", value: "\(telemetryMetrics.activeTraces)"),
            SummaryMetric(id: "summary.projectLoaded", title: "Project Loaded", value: projectManager.currentProject == nil ? "No" : "Yes")
        ]

        return DiagnosticsSnapshot(
            healthRows: healthRows,
            telemetryMetrics: telemetryMetrics,
            successRateText: successRateText,
            successRateColor: successRateColor,
            syncRows: syncRows,
            pluginRows: pluginRows,
            connectorRows: connectorRows,
            summaryItems: summaryItems,
            lastAuditText: relativeAuditText(from: health.lastCheck)
        )
    }

    private func successRateValue(for metrics: TelemetryMetrics) -> Double {
        guard metrics.totalTraces > 0 else { return 100 }
        return Double(metrics.successCount) / Double(metrics.totalTraces) * 100
    }

    private func percentageText(from value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private func relativeAuditText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func scopeTitle(_ scope: SDKScope) -> String {
        switch scope {
        case .custom(let query):
            return query.isEmpty ? "Custom" : query.capitalized
        default:
            return String(describing: scope).capitalized
        }
    }
}

private struct DiagnosticsSnapshot {
    let healthRows: [HealthMetricDisplay]
    let telemetryMetrics: TelemetryMetrics
    let successRateText: String
    let successRateColor: Color
    let syncRows: [HealthMetricDisplay]
    let pluginRows: [HealthMetricDisplay]
    let connectorRows: [HealthMetricDisplay]
    let summaryItems: [SummaryMetric]
    let lastAuditText: String
}

private struct HealthMetricDisplay: Identifiable {
    let id: String
    let title: String
    let value: String
    let indicator: HealthIndicator
}

private struct HealthIndicator {
    let text: String
    let tint: Color
    let systemImage: String
}

private struct SummaryMetric: Identifiable {
    let id: String
    let title: String
    let value: String
}

private struct DiagnosticsHeaderView: View {
    let lastAuditText: String
    let onRunAudit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SDK Diagnostics")
                .font(.title3.bold())
            HStack {
                Text("Last audit: \(lastAuditText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                Button(action: onRunAudit) {
                    Label("Run System Audit", systemImage: "arrow.clockwise.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HealthMetricRow: View {
    let metric: HealthMetricDisplay

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .font(.subheadline.weight(.medium))
                Text(metric.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HealthIndicatorBadge(indicator: metric.indicator)
        }
        .padding(.vertical, 2)
    }
}

private struct TelemetryCard: View {
    let metrics: TelemetryMetrics
    let successRateText: String
    let successRateColor: Color

    private var telemetryRows: [HealthMetricDisplay] {
        [
            HealthMetricDisplay(
                id: "telemetry.latency",
                title: "Average Latency",
                value: "\(Int(metrics.averageDurationMs.rounded()))ms",
                indicator: HealthIndicator(text: "Latency", tint: .secondary, systemImage: "clock.fill")
            ),
            HealthMetricDisplay(
                id: "telemetry.total",
                title: "Total Traces",
                value: "\(metrics.totalTraces)",
                indicator: HealthIndicator(text: "Traces", tint: .secondary, systemImage: "waveform.path.ecg")
            ),
            HealthMetricDisplay(
                id: "telemetry.success",
                title: "Successful Traces",
                value: "\(metrics.successCount)",
                indicator: HealthIndicator(text: successRateText, tint: successRateColor, systemImage: "checkmark.seal.fill")
            ),
            HealthMetricDisplay(
                id: "telemetry.failure",
                title: "Failure Count",
                value: "\(metrics.failureCount)",
                indicator: HealthIndicator(
                    text: metrics.failureCount == 0 ? "Clear" : "Investigate",
                    tint: metrics.failureCount == 0 ? .green : .orange,
                    systemImage: metrics.failureCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            )
        ]
    }

    var body: some View {
        DiagnosticsStatusPanel(
            title: "Performance Analytics",
            rows: telemetryRows,
            emptyMessage: "No telemetry data"
        )
    }
}

private struct DiagnosticsStatusPanel: View {
    let title: String
    let rows: [HealthMetricDisplay]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if rows.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows) { row in
                        HealthMetricRow(metric: row)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct MetricsSummaryView: View {
    let items: [SummaryMetric]

    var body: some View {
        let rowCount = (items.count + 1) / 2

        VStack(alignment: .leading, spacing: 10) {
            Text("Metrics Summary")
                .font(.headline)

            if items.isEmpty {
                Text("No summary metrics available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    ForEach(0..<rowCount, id: \.self) { rowIndex in
                        GridRow {
                            summaryCell(items[rowIndex * 2])

                            if let secondaryItem = metric(at: (rowIndex * 2) + 1) {
                                summaryCell(secondaryItem)
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metric(at index: Int) -> SummaryMetric? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    private func summaryCell(_ item: SummaryMetric) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HealthIndicatorBadge: View {
    let indicator: HealthIndicator

    var body: some View {
        Label(indicator.text, systemImage: indicator.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(indicator.tint)
            .background(indicator.tint.opacity(0.15), in: Capsule())
    }
}
