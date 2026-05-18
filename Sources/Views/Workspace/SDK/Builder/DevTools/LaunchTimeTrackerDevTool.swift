import SwiftUI

struct LaunchTimeTrackerTool: DevTool {
    let id = UUID()
    let name = "Launch Time Tracker"
    let category: DevToolCategory = .performance
    let icon = "timer"
    let description = "Track and analyze app launch times"
    func render() -> some View { LaunchTimeTrackerDevToolView() }
}

struct LaunchTimeTrackerDevToolView: View {
    @State private var processStart: Date = {
        let info = ProcessInfo.processInfo
        return Date(timeIntervalSinceNow: -info.systemUptime)
    }()

    private var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }

    var body: some View {
        Form {
            Section("Launch Info") {
                LabeledContent("Process Started") {
                    Text(processStart, style: .time)
                }
                LabeledContent("System Uptime", value: formatDuration(uptime))
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
            }
            Section("Performance Metrics") {
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("Physical Memory", value: formatBytes(ProcessInfo.processInfo.physicalMemory))
                LabeledContent("Thermal State", value: thermalState)
                LabeledContent("Low Power", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Yes" : "No")
            }
            Section("Optimization Tips") {
                Label("Defer non-essential initialization", systemImage: "arrow.right.circle")
                Label("Use lazy loading for heavy views", systemImage: "arrow.right.circle")
                Label("Minimize synchronous network calls", systemImage: "arrow.right.circle")
                Label("Profile with Instruments", systemImage: "arrow.right.circle")
            }
            .font(.caption)
        }
        .navigationTitle("Launch Time Tracker")
    }

    private var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = Int(interval) % 3600 / 60
        let s = Int(interval) % 60
        return String(format: "%dh %dm %ds", h, m, s)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
