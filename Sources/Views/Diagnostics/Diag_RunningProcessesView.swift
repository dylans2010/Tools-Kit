import SwiftUI
import Darwin

struct Diag_RunningProcessesView: View {
    @State private var processInfo: [(String, String)] = []
    @State private var systemStats: [(String, String)] = []
    @State private var isRefreshing = false

    var body: some View {
        Form {
            Section("Active Process Info") {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Process Monitor")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Current Process") {
                ForEach(processInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption.monospaced()).textSelection(.enabled) }
                }
            }

            Section("System Statistics") {
                ForEach(systemStats, id: \.0) { stat in
                    LabeledContent(stat.0) { Text(stat.1).font(.caption) }
                }
            }

            Section {
                Button { refreshProcess() } label: {
                    HStack {
                        if isRefreshing { ProgressView().scaleEffect(0.8) }
                        Image(systemName: "arrow.clockwise"); Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("Running Processes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshProcess() }
    }

    private func refreshProcess() {
        isRefreshing = true
        var info: [(String, String)] = []

        let pi = ProcessInfo.processInfo
        info.append(("Process Name", pi.processName))
        info.append(("Process ID", "\(pi.processIdentifier)"))
        info.append(("Host Name", pi.hostName))
        info.append(("OS Version", pi.operatingSystemVersionString))
        info.append(("Arguments", pi.arguments.prefix(3).joined(separator: " ")))
        info.append(("Active CPUs", "\(pi.activeProcessorCount)"))
        info.append(("Uptime", formatUptime(pi.systemUptime)))

        processInfo = info

        var stats: [(String, String)] = []
        stats.append(("Total CPUs", "\(pi.processorCount)"))
        stats.append(("Physical RAM", formatBytes(pi.physicalMemory)))
        stats.append(("Thermal State", thermalStr(pi.thermalState)))
        stats.append(("Low Power Mode", pi.isLowPowerModeEnabled ? "Enabled" : "Disabled"))

        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            stats.append(("App Memory", formatBytes(UInt64(taskInfo.resident_size))))
            stats.append(("Virtual Memory", formatBytes(UInt64(taskInfo.virtual_size))))
        }

        systemStats = stats
        isRefreshing = false
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let t = Int(seconds)
        let d = t / 86400; let h = (t % 86400) / 3600; let m = (t % 3600) / 60
        return d > 0 ? "\(d)d \(h)h \(m)m" : "\(h)h \(m)m"
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func thermalStr(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
