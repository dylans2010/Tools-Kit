import SwiftUI

struct CPUMonitorTool: DevTool {
    let id = UUID()
    let name = "CPU Monitor"
    let category: DevToolCategory = .performance
    let icon = "cpu"
    let description = "Monitor CPU usage per thread"
    func render() -> some View { CPUMonitorDevToolView() }
}

struct CPUMonitorDevToolView: View {
    @State private var cpuUsage: Double = 0
    @State private var history: [Double] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("CPU Usage") {
                HStack {
                    Text("\(String(format: "%.1f", cpuUsage))%")
                        .font(.system(.largeTitle, design: .monospaced).bold())
                        .foregroundStyle(cpuUsage > 80 ? .red : cpuUsage > 50 ? .orange : .green)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(ProcessInfo.processInfo.activeProcessorCount) cores")
                            .font(.caption)
                        Text("Active").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Section("History") {
                if !history.isEmpty {
                    GeometryReader { geo in
                        ZStack {
                            Path { path in
                                let step = geo.size.width / Double(max(1, history.count - 1))
                                for (i, val) in history.enumerated() {
                                    let x = Double(i) * step
                                    let y = geo.size.height - (val / 100.0) * geo.size.height
                                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(Color.accentColor, lineWidth: 2)
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.2))
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.2))
                            }
                            .stroke(Color.red.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        }
                    }
                    .frame(height: 120)
                }
            }
            Section("Info") {
                LabeledContent("Processor Count", value: "\(ProcessInfo.processInfo.processorCount)")
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("Thermal State", value: thermalState)
            }
        }
        .navigationTitle("CPU Monitor")
        .onAppear { startMonitoring() }
        .onDisappear { timer?.invalidate() }
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

    private func startMonitoring() {
        updateCPU()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in updateCPU() }
    }

    private func updateCPU() {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS,
              let threads = threadList else { return }
        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if result == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride))
        cpuUsage = totalUsage
        history.append(totalUsage)
        if history.count > 60 { history.removeFirst() }
    }
}
