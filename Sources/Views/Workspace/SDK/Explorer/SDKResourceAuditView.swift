import SwiftUI

struct SDKResourceAuditView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @State private var auditEntries: [ResourceAuditEntry] = []
    @State private var isRefreshing = false

    struct ResourceAuditEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let cpuUsage: Double
        let memoryMB: Double
        let diskWriteMB: Double
        let networkThroughput: Double
    }

    var body: some View {
        List {
            Section(header: Text("Current Resource Utilization")) {
                let metrics = telemetry.getMetrics()
                HStack(spacing: 20) {
                    ResourceGauge(label: "Avg Latency", value: min(1.0, metrics.averageDurationMs / 1000), color: .blue, systemImage: "timer", unit: "ms", displayVal: "\(Int(metrics.averageDurationMs))")
                    ResourceGauge(label: "Health", value: Double(metrics.successCount) / Double(max(1, metrics.totalTraces)), color: .green, systemImage: "heart.fill", unit: "%", displayVal: "\(Int((Double(metrics.successCount) / Double(max(1, metrics.totalTraces))) * 100))")
                }
                .padding(.vertical)
            }

            Section(header: Text("Project Allocation Audit")) {
                if let project = projectManager.currentProject {
                    LabeledContent("Active Project", value: project.name)
                    LabeledContent("Scopes Enabled", value: "\(project.enabledScopes.count)")
                    LabeledContent("Plugin Count", value: "\(project.enabledPluginIDs.count)")
                    LabeledContent("Connector Count", value: "\(project.enabledConnectorIDs.count)")
                } else {
                    Text("No active project selected")
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("System Metrics (ProcessInfo)")) {
                LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)) GB")
                LabeledContent("Processor Count", value: "\(ProcessInfo.processInfo.processorCount)")
                LabeledContent("System Uptime", value: "\(Int(ProcessInfo.processInfo.systemUptime / 3600)) hours")
            }
        }
        .navigationTitle("Resource Audit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshAudit()
                } label: {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear { refreshAudit() }
    }

    private func refreshAudit() {
        isRefreshing = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

private struct ResourceGauge: View {
    let label: String
    let value: Double
    let color: Color
    let systemImage: String
    let unit: String
    let displayVal: String

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: systemImage)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(displayVal)
                        .font(.system(size: 12, weight: .bold))
                    Text(unit)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)

            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
