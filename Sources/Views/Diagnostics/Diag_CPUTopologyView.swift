import SwiftUI

/// Real CPU topology from sysctl. The previous version hardcoded
/// "Performance Cores 0.65 / Efficiency Cores 0.22" progress bars —
/// iOS does not expose per-cluster utilisation to apps, so those
/// bars were invented. This version reports the counts and CPU
/// identification that sysctl actually provides, and says plainly
/// that per-cluster utilisation is not exposed.
struct Diag_CPUTopologyView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        List {
            Section("Processor Layout") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption.monospaced()) }
                }
            }

            Section("Cluster Distribution") {
                Text("Per-cluster (performance vs. efficiency) utilisation is not exposed to iOS apps, so no utilisation bars are shown here. ProcessInfo and sysctl only report the counts above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh") { load() }
            }
        }
        .navigationTitle("CPU Topology")
        .onAppear { load() }
    }

    private func load() {
        var rows: [(String, String)] = []
        rows.append(("Logical Cores", "\(ProcessInfo.processInfo.processorCount)"))
        rows.append(("Active Cores", "\(ProcessInfo.processInfo.activeProcessorCount)"))
        rows.append(("Physical Cores (sysctl)", sysctlInt("hw.physicalcpu") ?? "—"))
        rows.append(("Logical Cores (sysctl)", sysctlInt("hw.logicalcpu") ?? "—"))
        rows.append(("CPU Type", sysctlInt("hw.cputype") ?? "—"))
        rows.append(("CPU Subtype", sysctlInt("hw.cpusubtype") ?? "—"))
        rows.append(("Physical Memory", ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)))
        rows.append(("Architecture", "arm64"))
        self.rows = rows
    }

    private func sysctlInt(_ name: String) -> String? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return "\(value)"
    }
}
