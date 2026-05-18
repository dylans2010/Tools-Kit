import SwiftUI

struct MemoryMonitorTool: DevTool {
    let id = UUID()
    let name = "Memory Monitor"
    let category: DevToolCategory = .performance
    let icon = "memorychip"
    let description = "Monitor app memory usage in real-time"
    func render() -> some View { MemoryMonitorDevToolView() }
}

struct MemoryMonitorDevToolView: View {
    @State private var memoryUsage: UInt64 = 0
    @State private var peakMemory: UInt64 = 0
    @State private var history: [Double] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Current Usage") {
                LabeledContent("Memory Used", value: formatBytes(memoryUsage))
                LabeledContent("Peak Memory", value: formatBytes(peakMemory))
                LabeledContent("Physical Memory", value: formatBytes(ProcessInfo.processInfo.physicalMemory))
            }
            Section("History") {
                if !history.isEmpty {
                    GeometryReader { geo in
                        Path { path in
                            let maxVal = history.max() ?? 1
                            let step = geo.size.width / Double(max(1, history.count - 1))
                            for (i, val) in history.enumerated() {
                                let x = Double(i) * step
                                let y = geo.size.height - (val / maxVal) * geo.size.height
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.accentColor, lineWidth: 2)
                    }
                    .frame(height: 120)
                } else {
                    Text("Collecting data...").foregroundStyle(.secondary)
                }
            }
            Section("System") {
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("Processor Count", value: "\(ProcessInfo.processInfo.processorCount)")
            }
        }
        .navigationTitle("Memory Monitor")
        .onAppear { startMonitoring() }
        .onDisappear { timer?.invalidate() }
    }

    private func startMonitoring() {
        updateMemory()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in updateMemory() }
    }

    private func updateMemory() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            memoryUsage = info.resident_size
            peakMemory = max(peakMemory, info.resident_size)
            history.append(Double(info.resident_size))
            if history.count > 60 { history.removeFirst() }
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
