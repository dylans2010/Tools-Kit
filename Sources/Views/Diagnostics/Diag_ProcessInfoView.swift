import SwiftUI

struct Diag_ProcessInfoView: View {
    private let info = ProcessInfo.processInfo

    var body: some View {
        Form {
            Section("Process") {
                LabeledContent("Process Name") { Text(info.processName) }
                LabeledContent("Process ID") { Text("\(info.processIdentifier)").monospacedDigit() }
                LabeledContent("Host Name") { Text(info.hostName) }
                LabeledContent("OS Version") { Text(info.operatingSystemVersionString) }
            }

            Section("Hardware") {
                LabeledContent("Total Processors") { Text("\(info.processorCount)") }
                LabeledContent("Active Processors") { Text("\(info.activeProcessorCount)") }
                LabeledContent("Physical Memory") {
                    Text(formatBytes(info.physicalMemory))
                        .monospacedDigit()
                }
            }

            Section("Runtime") {
                LabeledContent("System Uptime") {
                    Text(formatUptime(info.systemUptime))
                        .monospacedDigit()
                }
                LabeledContent("Thermal State") { Text(thermalString) }
                LabeledContent("Low Power Mode") {
                    Text(info.isLowPowerModeEnabled ? "On" : "Off")
                        .foregroundStyle(info.isLowPowerModeEnabled ? .orange : .green)
                }
            }

            Section("Environment") {
                LabeledContent("Arguments Count") { Text("\(info.arguments.count)") }
                LabeledContent("Environment Vars") { Text("\(info.environment.count)") }
            }
        }
        .navigationTitle("Process Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var thermalString: String {
        switch info.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 { return "\(d)d \(h)h \(m)m \(s)s" }
        return "\(h)h \(m)m \(s)s"
    }
}
