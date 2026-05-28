import SwiftUI

struct SDKBuildStatView: View {
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    @State private var lastUpdate = Date()
    @State private var binarySize: String = "Calculating..."

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Build Health")
                            .font(.headline)
                        Spacer()
                        Button(action: refreshData) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Text("Last refreshed: \(lastUpdate, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Build Metrics")) {
                let metrics = telemetry.getMetrics()

                MetricRow(name: "Total Trace Executions", value: "\(metrics.totalTraces)", icon: "waveform.path.ecg")
                MetricRow(name: "Average Execution Time", value: String(format: "%.2f ms", metrics.averageDurationMs), icon: "timer")
                MetricRow(name: "Success Rate", value: String(format: "%.1f%%", metrics.totalTraces > 0 ? (Double(metrics.successCount) / Double(metrics.totalTraces) * 100) : 0), icon: "checkmark.circle")
                MetricRow(name: "Active Operations", value: "\(metrics.activeTraces)", icon: "bolt.fill")
            }

            Section(header: Text("System Status")) {
                let warnings = logStore.entries.filter { $0.level == .warning }.count
                let errors = logStore.entries.filter { $0.level == .error }.count

                MetricRow(name: "Warning Count", value: "\(warnings)", icon: "exclamationmark.triangle", color: warnings > 0 ? .orange : .green)
                MetricRow(name: "Error Count", value: "\(errors)", icon: "xmark.octagon", color: errors > 0 ? .red : .green)
                MetricRow(name: "Binary Size", value: binarySize, icon: "doc.zipper")
            }

            Section(header: Text("Project Context")) {
                if let project = projectManager.currentProject {
                    LabeledContent("Project Name", value: project.name)
                    LabeledContent("Version", value: "\(project.version)")
                    LabeledContent("Health", value: project.healthStatus.rawValue.capitalized)
                } else {
                    Text("No active project").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Build Statistics")
        .task {
            refreshData()
        }
    }

    private func refreshData() {
        updateBinarySize()
        lastUpdate = Date()
    }

    private func updateBinarySize() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        do {
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
            let sdkBundles = files.filter { $0.pathExtension == "sdkbundle" }
                .sorted { (url1, url2) -> Bool in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return date1 > date2
                }

            if let latestBundle = sdkBundles.first {
                let resourceValues = try latestBundle.resourceValues(forKeys: [.fileSizeKey])
                if let size = resourceValues.fileSize {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    binarySize = formatter.string(fromByteCount: Int64(size))
                    return
                }
            }
        } catch {
            binarySize = "Unknown"
        }
        binarySize = "No build found"
    }
}

struct MetricRow: View {
    let name: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Label(name, systemImage: icon)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}
