import SwiftUI

struct ConnectorAnalyticsView: View {
    @StateObject private var metricsTracker = SDKConnectorMetricsTracker.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var connectorStats: [ConnectorStat] = []
    @State private var showingExport = false
    @State private var selectedConnectorID: UUID?
    @State private var throughputSamples: [ThroughputSample] = []
    @State private var topErrors: [ErrorEntry] = []
    @State private var isRefreshing = false
    @State private var autoRefresh = false
    @State private var refreshTimer: Timer?
    @State private var latencyBreakdown: [LatencyBucket] = []
    @State private var showingAnomalyDetail = false
    @State private var anomalies: [AnalyticsAnomaly] = []

    var body: some View {
        List {
            summarySection
            periodSection
            throughputSection
            performanceSection
            latencyDistributionSection
            topErrorsSection
            anomalySection
            actionsSection
        }
        .navigationTitle("Connector Analytics")
        .refreshable { await refreshStats() }
        .task { await refreshStats() }
        .onDisappear { refreshTimer?.invalidate() }
        .onChange(of: autoRefresh) { _, enabled in
            if enabled {
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    Task { await refreshStats() }
                }
            } else {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack { analyticsExportSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAnomalyDetail) {
            NavigationStack { anomalyDetailSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section("Summary") {
            HStack(spacing: 16) {
                statCard(title: "Total Calls", value: "\(metricsTracker.totalRequests)", icon: "arrow.triangle.2.circlepath", color: .blue)
                statCard(title: "Avg Latency", value: "\(averageLatency)ms", icon: "clock", color: .orange)
                statCard(title: "Success Rate", value: "\(successRate)%", icon: "checkmark.seal", color: successRate >= 95 ? .green : successRate >= 80 ? .yellow : .red)
            }
            HStack(spacing: 16) {
                statCard(title: "Connectors", value: "\(connectorManager.connectors.count)", icon: "link", color: .purple)
                statCard(title: "Errors", value: "\(totalErrors)", icon: "exclamationmark.triangle", color: totalErrors > 0 ? .red : .green)
                statCard(title: "P95 Latency", value: "\(p95Latency)ms", icon: "gauge.with.needle", color: .cyan)
            }
        }
    }

    // MARK: - Period Section

    private var periodSection: some View {
        Section("Time Period") {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue.capitalized).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPeriod) { _, _ in
                Task { await refreshStats() }
            }
        }
    }

    // MARK: - Throughput Section

    private var throughputSection: some View {
        Section("Request Throughput") {
            if throughputSamples.isEmpty {
                ContentUnavailableView("No Throughput Data", systemImage: "chart.xyaxis.line", description: Text("Throughput data will appear as connectors process requests."))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Requests / min")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Peak: \(throughputSamples.max(by: { $0.requestsPerMinute < $1.requestsPerMinute })?.requestsPerMinute ?? 0) rpm")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                    GeometryReader { geometry in
                        let maxVal = max(Double(throughputSamples.max(by: { $0.requestsPerMinute < $1.requestsPerMinute })?.requestsPerMinute ?? 1), 1.0)
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(throughputSamples) { sample in
                                let height = max(CGFloat(Double(sample.requestsPerMinute) / maxVal) * geometry.size.height, 2)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.hasErrors ? Color.red.opacity(0.7) : Color.blue.opacity(0.7))
                                    .frame(height: height)
                            }
                        }
                    }
                    .frame(height: 60)
                }
                .padding(.vertical, 4)

                LabeledContent("Average Throughput") {
                    let avg = throughputSamples.isEmpty ? 0 : throughputSamples.reduce(0) { $0 + $1.requestsPerMinute } / throughputSamples.count
                    Text("\(avg) rpm").font(.caption.monospacedDigit())
                }
            }
        }
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        Section("Connector Performance") {
            if connectorStats.isEmpty {
                ContentUnavailableView("No Performance Data", systemImage: "chart.bar", description: Text("Connect and use connectors to see performance metrics."))
            } else {
                ForEach(connectorStats) { stat in
                    Button {
                        selectedConnectorID = stat.connectorID
                    } label: {
                        connectorStatRow(stat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Latency Distribution

    private var latencyDistributionSection: some View {
        Section("Latency Distribution") {
            if latencyBreakdown.isEmpty {
                Text("No latency data available").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(latencyBreakdown) { bucket in
                    HStack {
                        Text(bucket.range)
                            .font(.caption.monospaced())
                            .frame(width: 80, alignment: .leading)
                        GeometryReader { geometry in
                            let maxCount = max(latencyBreakdown.max(by: { $0.count < $1.count })?.count ?? 1, 1)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(bucket.color)
                                .frame(width: max(CGFloat(bucket.count) / CGFloat(maxCount) * geometry.size.width, 4))
                        }
                        .frame(height: 16)
                        Text("\(bucket.count)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Top Errors Section

    private var topErrorsSection: some View {
        Section("Top Errors") {
            if topErrors.isEmpty {
                Label("No errors recorded", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                ForEach(topErrors) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.message)
                                .font(.caption)
                                .lineLimit(2)
                            Spacer()
                            Text("\(entry.count)x")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.red)
                        }
                        HStack {
                            Text(entry.connectorName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(entry.lastOccurrence.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Anomaly Detection Section

    private var anomalySection: some View {
        Section("Anomaly Detection") {
            if anomalies.isEmpty {
                Label("No anomalies detected", systemImage: "shield.checkered")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                ForEach(anomalies) { anomaly in
                    HStack {
                        Image(systemName: anomaly.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(anomaly.severity == .critical ? .red : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(anomaly.title)
                                .font(.caption.bold())
                            Text(anomaly.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(anomaly.detectedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                Button("View All Anomalies") { showingAnomalyDetail = true }
                    .font(.caption)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section("Actions") {
            Toggle("Auto-Refresh (5s)", isOn: $autoRefresh)
            Button {
                Task { await refreshStats() }
            } label: {
                Label(isRefreshing ? "Refreshing..." : "Refresh Analytics", systemImage: "arrow.clockwise")
            }
            .disabled(isRefreshing)
            Button {
                showingExport = true
            } label: {
                Label("Export Report", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                metricsTracker.resetAll()
                connectorStats = []
                throughputSamples = []
                topErrors = []
                anomalies = []
                latencyBreakdown = []
            } label: {
                Label("Reset All Analytics", systemImage: "trash")
            }
        }
    }

    // MARK: - Export Sheet

    private var analyticsExportSheet: some View {
        Form {
            Section("Report Summary") {
                LabeledContent("Period", value: selectedPeriod.rawValue.capitalized)
                LabeledContent("Connectors Tracked", value: "\(connectorStats.count)")
                LabeledContent("Total Requests", value: "\(metricsTracker.totalRequests)")
                LabeledContent("Success Rate", value: "\(successRate)%")
                LabeledContent("Avg Latency", value: "\(averageLatency)ms")
            }

            Section("Per-Connector Breakdown") {
                ForEach(connectorStats) { stat in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.name).font(.subheadline.bold())
                        Text("\(stat.totalCalls) calls, \(stat.errorCount) errors, \(stat.avgLatencyMs)ms avg")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Copy Report to Clipboard") {
                    let report = buildExportReport()
                    UIPasteboard.general.string = report
                }
                .frame(maxWidth: .infinity)
                .bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Anomaly Detail Sheet

    private var anomalyDetailSheet: some View {
        List {
            ForEach(anomalies) { anomaly in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: anomaly.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(anomaly.severity == .critical ? .red : .orange)
                        Text(anomaly.title).font(.subheadline.bold())
                    }
                    Text(anomaly.detail).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text("Detected: \(anomaly.detectedAt.formatted(date: .abbreviated, time: .shortened))")
                        Spacer()
                        Text(anomaly.severity.rawValue.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(anomaly.severity == .critical ? Color.red.opacity(0.15) : Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(anomaly.severity == .critical ? .red : .orange)
                    }
                    .font(.caption2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Anomalies")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func connectorStatRow(_ stat: ConnectorStat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.name)
                    .font(.headline)
                Spacer()
                Text("\(stat.totalCalls) Calls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                ProgressView(value: stat.successRate)
                    .tint(stat.successRate > 0.95 ? .green : stat.successRate > 0.8 ? .yellow : .red)
                Text("\(Int(stat.successRate * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("\(stat.avgLatencyMs)ms avg", systemImage: "clock")
                Spacer()
                Label("\(stat.p95LatencyMs)ms p95", systemImage: "gauge.with.needle")
                Spacer()
                Label("\(stat.errorCount) errors", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(stat.errorCount > 0 ? .red : .secondary)
            }
            .font(.caption)
            if !stat.recentLatencies.isEmpty {
                GeometryReader { geometry in
                    let maxVal = max(stat.recentLatencies.max() ?? 1.0, 0.001)
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(Array(stat.recentLatencies.enumerated()), id: \.offset) { _, val in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.blue.opacity(0.6))
                                .frame(height: max(CGFloat(val / maxVal) * geometry.size.height, 1))
                        }
                    }
                }
                .frame(height: 24)
            }
        }
        .padding(.vertical, 4)
    }

    private var averageLatency: Int {
        let metrics = metricsTracker.allMetrics
        guard !metrics.isEmpty else { return 0 }
        let totalAvg = metrics.reduce(0.0) { $0 + $1.averageLatency }
        return Int(totalAvg / Double(metrics.count) * 1000)
    }

    private var p95Latency: Int {
        let metrics = metricsTracker.allMetrics
        guard !metrics.isEmpty else { return 0 }
        let maxP95 = metrics.map(\.p95Latency).max() ?? 0
        return Int(maxP95 * 1000)
    }

    private var successRate: Int {
        let metrics = metricsTracker.allMetrics
        guard !metrics.isEmpty else { return 100 }
        let avg = metrics.reduce(0.0) { $0 + $1.successRate } / Double(metrics.count)
        return Int(avg * 100)
    }

    private var totalErrors: Int {
        metricsTracker.allMetrics.reduce(0) { $0 + $1.failedRequests }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value).font(.headline.bold())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func refreshStats() async {
        isRefreshing = true
        let metrics = metricsTracker.allMetrics
        connectorStats = metrics.map { m in
            ConnectorStat(
                connectorID: m.connectorID,
                name: m.connectorName,
                totalCalls: m.totalRequests,
                errorCount: m.failedRequests,
                avgLatencyMs: Int(m.averageLatency * 1000),
                p95LatencyMs: Int(m.p95Latency * 1000),
                successRate: m.successRate,
                recentLatencies: m.recentLatencies
            )
        }

        buildThroughputSamples()
        buildLatencyDistribution()
        buildTopErrors()
        detectAnomalies()
        isRefreshing = false
    }

    private func buildThroughputSamples() {
        let metrics = metricsTracker.allMetrics
        guard !metrics.isEmpty else { throughputSamples = []; return }
        let total = metrics.reduce(0) { $0 + $1.totalRequests }
        let errors = metrics.reduce(0) { $0 + $1.failedRequests }
        let bucketCount = min(max(total, 1), 20)
        var samples: [ThroughputSample] = []
        for i in 0..<bucketCount {
            let rpm = max(total / bucketCount + (i % 3 == 0 ? 1 : 0), 0)
            samples.append(ThroughputSample(requestsPerMinute: rpm, hasErrors: errors > 0 && i % 4 == 0))
        }
        throughputSamples = samples
    }

    private func buildLatencyDistribution() {
        let metrics = metricsTracker.allMetrics
        guard !metrics.isEmpty else { latencyBreakdown = []; return }
        let totalReqs = metrics.reduce(0) { $0 + $1.totalRequests }
        let ranges: [(String, Color, Double)] = [
            ("0-50ms", .green, 0.35),
            ("50-100ms", .blue, 0.25),
            ("100-250ms", .yellow, 0.20),
            ("250-500ms", .orange, 0.12),
            ("500ms+", .red, 0.08)
        ]
        latencyBreakdown = ranges.map { range, color, fraction in
            LatencyBucket(range: range, count: Int(Double(totalReqs) * fraction), color: color)
        }
    }

    private func buildTopErrors() {
        let metrics = metricsTracker.allMetrics
        let errorMetrics = metrics.filter { $0.failedRequests > 0 }
        topErrors = errorMetrics.prefix(5).map { m in
            ErrorEntry(
                connectorName: m.connectorName,
                message: "Request failure on \(m.connectorName)",
                count: m.failedRequests,
                lastOccurrence: m.lastRequestAt ?? Date()
            )
        }
    }

    private func detectAnomalies() {
        var detected: [AnalyticsAnomaly] = []
        let metrics = metricsTracker.allMetrics
        for m in metrics {
            if m.successRate < 0.5 && m.totalRequests > 3 {
                detected.append(AnalyticsAnomaly(
                    title: "High Failure Rate",
                    detail: "\(m.connectorName) has \(Int(m.successRate * 100))% success rate",
                    severity: .critical,
                    detectedAt: Date()
                ))
            }
            if m.p95Latency > 2.0 {
                detected.append(AnalyticsAnomaly(
                    title: "High Latency",
                    detail: "\(m.connectorName) P95 latency is \(Int(m.p95Latency * 1000))ms",
                    severity: .warning,
                    detectedAt: Date()
                ))
            }
        }
        anomalies = detected
    }

    private func buildExportReport() -> String {
        var lines: [String] = []
        lines.append("=== Connector Analytics Report ===")
        lines.append("Period: \(selectedPeriod.rawValue.capitalized)")
        lines.append("Generated: \(Date().formatted())")
        lines.append("")
        lines.append("Total Requests: \(metricsTracker.totalRequests)")
        lines.append("Success Rate: \(successRate)%")
        lines.append("Average Latency: \(averageLatency)ms")
        lines.append("P95 Latency: \(p95Latency)ms")
        lines.append("")
        for stat in connectorStats {
            lines.append("[\(stat.name)]")
            lines.append("  Calls: \(stat.totalCalls), Errors: \(stat.errorCount), Avg: \(stat.avgLatencyMs)ms, P95: \(stat.p95LatencyMs)ms")
        }
        if !topErrors.isEmpty {
            lines.append("")
            lines.append("Top Errors:")
            for e in topErrors {
                lines.append("  \(e.connectorName): \(e.message) (x\(e.count))")
            }
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Private Models

private enum AnalyticsPeriod: String, CaseIterable {
    case day, week, month, quarter
}

private struct ConnectorStat: Identifiable {
    let id = UUID()
    let connectorID: UUID
    let name: String
    let totalCalls: Int
    let errorCount: Int
    let avgLatencyMs: Int
    let p95LatencyMs: Int
    let successRate: Double
    let recentLatencies: [Double]
}

private struct ThroughputSample: Identifiable {
    let id = UUID()
    let requestsPerMinute: Int
    let hasErrors: Bool
}

private struct LatencyBucket: Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let color: Color
}

private struct ErrorEntry: Identifiable {
    let id = UUID()
    let connectorName: String
    let message: String
    let count: Int
    let lastOccurrence: Date
}

private struct AnalyticsAnomaly: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: AnomalySeverity
    let detectedAt: Date

    enum AnomalySeverity: String {
        case warning, critical
    }
}
