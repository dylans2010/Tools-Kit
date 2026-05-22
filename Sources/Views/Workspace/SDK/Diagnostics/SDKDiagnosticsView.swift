import SwiftUI

struct SDKDiagnosticsView: View {
    @StateObject private var bgEngine = SDKBackgroundEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var showingExportReport = false
    @State private var showingDependencyGraph = false
    @State private var showingResourceMonitor = false
    @State private var autoRefreshDiag = false
    @State private var refreshTimer: Timer?
    @State private var diagnosticAlerts: [DiagnosticAlert] = []
    private let successRateHealthyThreshold: Double = 90

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

                ResourceMonitorPanel(
                    memoryGB: ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024,
                    processors: ProcessInfo.processInfo.activeProcessorCount,
                    uptime: ProcessInfo.processInfo.systemUptime,
                    thermalState: ProcessInfo.processInfo.thermalState
                )

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

                DiagnosticAlertsPanel(alerts: diagnosticAlerts)

                DependencyHealthPanel(
                    connectorCount: connectorManager.connectors.count,
                    connectedCount: connectorManager.connectors.filter { $0.status == .connected }.count,
                    pluginCount: pluginManager.plugins.count,
                    enabledPluginCount: pluginManager.plugins.filter(\.isEnabled).count
                )

                DiagnosticActionsPanel(
                    autoRefresh: $autoRefreshDiag,
                    onExport: { showingExportReport = true },
                    onClearAlerts: { diagnosticAlerts.removeAll() }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingExportReport = true } label: { Label("Export Report", systemImage: "square.and.arrow.up") }
                    Button { showingDependencyGraph = true } label: { Label("Dependency Graph", systemImage: "point.3.connected.trianglepath.dotted") }
                    Button { showingResourceMonitor = true } label: { Label("Resource Monitor", systemImage: "gauge.with.dots.needle.33percent") }
                    Divider()
                    Button { runFullDiagnostic() } label: { Label("Run Full Diagnostic", systemImage: "stethoscope") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .onAppear { checkForAlerts() }
        .onDisappear { refreshTimer?.invalidate() }
        .onChange(of: autoRefreshDiag) { _, enabled in
            if enabled {
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                    checkForAlerts()
                }
            } else {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
        .sheet(isPresented: $showingExportReport) {
            NavigationStack { diagnosticExportSheet(snapshot) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDependencyGraph) {
            NavigationStack { dependencyGraphSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingResourceMonitor) {
            NavigationStack { resourceMonitorSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func diagnosticExportSheet(_ snapshot: DiagnosticsSnapshot) -> some View {
        Form {
            Section("Report Summary") {
                LabeledContent("Health Status", value: "\(snapshot.healthRows.filter { $0.indicator.tint == .green }.count)/\(snapshot.healthRows.count) healthy")
                LabeledContent("Success Rate", value: snapshot.successRateText)
                LabeledContent("Connectors", value: "\(snapshot.connectorRows.count)")
                LabeledContent("Plugins", value: "\(snapshot.pluginRows.count)")
                LabeledContent("Alerts", value: "\(diagnosticAlerts.count)")
            }
            Section("Telemetry") {
                LabeledContent("Total Traces", value: "\(snapshot.telemetryMetrics.totalTraces)")
                LabeledContent("Avg Latency", value: "\(Int(snapshot.telemetryMetrics.averageDurationMs))ms")
                LabeledContent("Successes", value: "\(snapshot.telemetryMetrics.successCount)")
                LabeledContent("Failures", value: "\(snapshot.telemetryMetrics.failureCount)")
            }
            Section {
                Button("Copy Report to Clipboard") {
                    let report = buildDiagnosticReport(snapshot)
                    UIPasteboard.general.string = report
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Diagnostic Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dependencyGraphSheet: some View {
        List {
            Section("Connector Dependencies") {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    HStack {
                        Image(systemName: "link").foregroundStyle(connector.isConnected ? .green : .secondary)
                        VStack(alignment: .leading) {
                            Text(connector.name).font(.subheadline)
                            Text(connector.status.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Plugin Dependencies") {
                ForEach(pluginManager.plugins, id: \.id) { plugin in
                    HStack {
                        Image(systemName: "puzzlepiece").foregroundStyle(plugin.isEnabled ? .blue : .secondary)
                        VStack(alignment: .leading) {
                            Text(plugin.name).font(.subheadline)
                            Text("v\(plugin.version)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dependencies")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resourceMonitorSheet: some View {
        List {
            Section("System Resources") {
                LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB")
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("System Uptime") {
                    let uptime = ProcessInfo.processInfo.systemUptime
                    Text("\(Int(uptime / 3600))h \(Int(uptime.truncatingRemainder(dividingBy: 3600) / 60))m")
                }
                LabeledContent("Thermal State") {
                    let state = ProcessInfo.processInfo.thermalState
                    Text(thermalLabel(state)).foregroundStyle(thermalColor(state))
                }
            }
            Section("Log Statistics") {
                LabeledContent("Total Entries", value: "\(logStore.entries.count)")
                LabeledContent("Errors", value: "\(logStore.entries.filter { $0.level == .error }.count)")
                LabeledContent("Warnings", value: "\(logStore.entries.filter { $0.level == .warning }.count)")
            }
        }
        .navigationTitle("Resource Monitor")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkForAlerts() {
        var alerts: [DiagnosticAlert] = []
        let health = bgEngine.systemHealth
        if !health.connectorReachability {
            alerts.append(DiagnosticAlert(severity: .critical, message: "Connector reachability is degraded", source: "System Health"))
        }
        if !health.pluginSandboxStatus {
            alerts.append(DiagnosticAlert(severity: .warning, message: "Plugin sandbox status warning", source: "System Health"))
        }
        if !health.coreDataHealth {
            alerts.append(DiagnosticAlert(severity: .critical, message: "Core data store is unavailable", source: "System Health"))
        }
        let metrics = telemetry.getMetrics()
        if metrics.totalTraces > 0 {
            let successRate = Double(metrics.successCount) / Double(metrics.totalTraces) * 100
            if successRate < successRateHealthyThreshold {
                alerts.append(DiagnosticAlert(severity: .warning, message: "Success rate below \(Int(successRateHealthyThreshold))%: \(Int(successRate))%", source: "Telemetry"))
            }
        }
        diagnosticAlerts = alerts
    }

    private func runFullDiagnostic() {
        bgEngine.startHealthCheckLoop()
        checkForAlerts()
    }

    private func buildDiagnosticReport(_ snapshot: DiagnosticsSnapshot) -> String {
        var lines: [String] = []
        lines.append("=== SDK Diagnostics Report ===")
        lines.append("Generated: \(Date().formatted())")
        lines.append("")
        lines.append("[System Health]")
        for row in snapshot.healthRows {
            lines.append("  \(row.title): \(row.value) — \(row.indicator.text)")
        }
        lines.append("")
        lines.append("[Telemetry]")
        lines.append("  Total: \(snapshot.telemetryMetrics.totalTraces), Success: \(snapshot.telemetryMetrics.successCount), Fail: \(snapshot.telemetryMetrics.failureCount)")
        lines.append("  Avg Latency: \(Int(snapshot.telemetryMetrics.averageDurationMs))ms, Success Rate: \(snapshot.successRateText)")
        lines.append("")
        lines.append("[Connectors]")
        for row in snapshot.connectorRows { lines.append("  \(row.title): \(row.indicator.text)") }
        lines.append("[Plugins]")
        for row in snapshot.pluginRows { lines.append("  \(row.title): \(row.indicator.text)") }
        if !diagnosticAlerts.isEmpty {
            lines.append("")
            lines.append("[Alerts]")
            for alert in diagnosticAlerts { lines.append("  [\(alert.severity.rawValue.uppercased())] \(alert.message)") }
        }
        return lines.joined(separator: "\n")
    }

    private func thermalLabel(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func thermalColor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private func makeSnapshot() -> DiagnosticsSnapshot {
        let health = bgEngine.systemHealth
        let telemetryMetrics = telemetry.getMetrics()
        let successRate = successRateValue(for: telemetryMetrics)
        let successRateText = percentageText(from: successRate)
        let successRateColor = successRate >= successRateHealthyThreshold ? Color.green : Color.orange

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
            SummaryMetric(id: "summary.projectLoaded", title: "Project Loaded", value: projectManager.currentProject == nil ? "None" : "Loaded")
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
        case .custom:
            return "Custom"
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
                value: "\(Int(metrics.averageDurationMs))ms",
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
                            if let primaryItem = metric(at: rowIndex * 2) {
                                summaryCell(primaryItem)
                            } else {
                                EmptyView()
                            }

                            if let secondaryItem = metric(at: (rowIndex * 2) + 1) {
                                summaryCell(secondaryItem)
                            } else {
                                EmptyView()
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

// MARK: - New Diagnostic Panels

private struct ResourceMonitorPanel: View {
    let memoryGB: UInt64
    let processors: Int
    let uptime: TimeInterval
    let thermalState: ProcessInfo.ThermalState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resource Monitor")
                .font(.headline)
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Image(systemName: "memorychip").foregroundStyle(.blue)
                    Text("\(memoryGB) GB").font(.caption.bold())
                    Text("Memory").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Image(systemName: "cpu").foregroundStyle(.purple)
                    Text("\(processors)").font(.caption.bold())
                    Text("CPUs").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Image(systemName: "clock").foregroundStyle(.green)
                    Text("\(Int(uptime / 3600))h").font(.caption.bold())
                    Text("Uptime").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Image(systemName: "thermometer").foregroundStyle(thermalColor)
                    Text(thermalText).font(.caption.bold())
                    Text("Thermal").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var thermalText: String {
        switch thermalState {
        case .nominal: return "OK"
        case .fair: return "Fair"
        case .serious: return "Warn"
        case .critical: return "Hot"
        @unknown default: return "?"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }
}

private struct DiagnosticAlertsPanel: View {
    let alerts: [DiagnosticAlert]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Alerts").font(.headline)
                Spacer()
                if !alerts.isEmpty {
                    Text("\(alerts.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
            }
            if alerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                    Text("No active alerts").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                ForEach(alerts) { alert in
                    HStack(spacing: 8) {
                        Image(systemName: alert.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(alert.severity == .critical ? .red : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.message).font(.caption)
                            Text(alert.source).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DependencyHealthPanel: View {
    let connectorCount: Int
    let connectedCount: Int
    let pluginCount: Int
    let enabledPluginCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dependency Health")
                .font(.headline)
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(connectedCount)/\(connectorCount)").font(.caption.bold()).foregroundStyle(.blue)
                    Text("Connectors").font(.caption2).foregroundStyle(.secondary)
                    ProgressView(value: connectorCount > 0 ? Double(connectedCount) / Double(connectorCount) : 1.0)
                        .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(enabledPluginCount)/\(pluginCount)").font(.caption.bold()).foregroundStyle(.purple)
                    Text("Plugins").font(.caption2).foregroundStyle(.secondary)
                    ProgressView(value: pluginCount > 0 ? Double(enabledPluginCount) / Double(pluginCount) : 1.0)
                        .tint(.purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DiagnosticActionsPanel: View {
    @Binding var autoRefresh: Bool
    let onExport: () -> Void
    let onClearAlerts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.headline)
            Toggle("Auto-Refresh (10s)", isOn: $autoRefresh)
                .font(.subheadline)
            HStack(spacing: 12) {
                Button(action: onExport) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                Button(action: onClearAlerts) {
                    Label("Clear Alerts", systemImage: "xmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DiagnosticAlert: Identifiable {
    let id = UUID()
    let severity: AlertSeverity
    let message: String
    let source: String

    enum AlertSeverity: String {
        case warning, critical
    }
}
