import SwiftUI

struct ResourceMonitorView: View {
    @ObservedObject var healthService = SystemHealthService.shared

    var body: some View {
        List {
            Section("Current Resource Usage") {
                if let metrics = healthService.currentMetrics {
                    resourceRow(label: "CPU Usage", value: String(format: "%.1f%%", metrics.cpuUsage * 100), color: .blue, progress: metrics.cpuUsage)
                    resourceRow(label: "Memory", value: ByteCountFormatter().string(fromByteCount: metrics.memoryUsage), color: .green, progress: Double(metrics.memoryUsage) / 1_000_000_000)
                    resourceRow(label: "Disk", value: ByteCountFormatter().string(fromByteCount: metrics.diskUsage), color: .orange, progress: 0.1)
                } else {
                    ProgressView("Gathering metrics...")
                }
            }

            Section("Utilization Trends") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CPU History (Last 5 mins)").font(.caption).foregroundStyle(.secondary)
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(healthService.metricsHistory.suffix(30)) { metric in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.blue)
                                .frame(width: 4, height: CGFloat(metric.cpuUsage * 100))
                        }
                    }
                    .frame(height: 100)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Resource Monitor")
    }

    private func resourceRow(label: String, value: String, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(value).font(.subheadline.bold())
            }
            ProgressView(value: progress)
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}

struct BackgroundTaskTrackerView: View {
    @ObservedObject var activityService = DeveloperActivityService.shared

    var body: some View {
        List {
            Section("System Maintenance Tasks") {
                // Sourced from real activity types
                taskRow(name: "App Sync", schedule: "On Demand", status: "Active")
                taskRow(name: "Key Rotation Check", schedule: "Daily", status: "Active")
                taskRow(name: "Audit Log Cleanup", schedule: "Weekly", status: "Pending")
            }

            Section("Execution History") {
                Text("Recent task executions will appear here.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Background Tasks")
    }

    private func taskRow(name: String, schedule: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.subheadline.bold())
                Text(schedule).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(status).font(.caption2.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.1), in: Capsule())
                .foregroundStyle(.green)
        }
    }
}
