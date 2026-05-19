import SwiftUI

struct CPUMonitorDevTool: DevTool {
    let id = "cpu-monitor"
    let name = "CPU Monitor"
    let category = DevToolCategory.performance
    let icon = "cpu"
    let description = "Real-time CPU usage monitoring"

    func render() -> some View {
        CPUMonitorView()
    }
}

struct CPUMonitorView: View {
    @StateObject private var viewModel = CPUMonitorViewModel()

    var body: some View {
        VStack(spacing: 20) {
            GeometryReader { geo in
                Path { path in
                    guard viewModel.usageHistory.count > 1 else { return }
                    let step = geo.size.width / CGFloat(viewModel.usageHistory.count - 1)
                    let height = geo.size.height

                    path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat((viewModel.usageHistory.first ?? 0)/100))))

                    for i in 1..<viewModel.usageHistory.count {
                        path.addLine(to: CGPoint(x: CGFloat(i) * step, y: height * (1 - CGFloat(viewModel.usageHistory[i]/100))))
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
            .frame(height: 200)
            .padding()

            Form {
                Section("Live Metrics") {
                    LabeledContent("Current Usage", value: String(format: "%.1f%%", viewModel.currentUsage))
                    LabeledContent("Peak Usage", value: String(format: "%.1f%%", viewModel.peakUsage))
                    LabeledContent("Cores Detected", value: "\(ProcessInfo.processInfo.processorCount)")
                }

                Section("System State") {
                    LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
                    LabeledContent("Thermal State", value: viewModel.thermalState)
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

class CPUMonitorViewModel: ObservableObject {
    @Published var currentUsage: Double = 0
    @Published var peakUsage: Double = 0
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 50)
    @Published var thermalState = "Fair"

    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
    }

    private func update() {
        var cpuLoad: host_cpu_load_info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let totalTicks = Double(cpuLoad.cpu_ticks.0 + cpuLoad.cpu_ticks.1 + cpuLoad.cpu_ticks.2 + cpuLoad.cpu_ticks.3)
            let idleTicks = Double(cpuLoad.cpu_ticks.3)
            let usage = (1.0 - (idleTicks / totalTicks)) * 100.0

            currentUsage = usage
            if usage > peakUsage { peakUsage = usage }

            usageHistory.removeFirst()
            usageHistory.append(usage)
        }

        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }
}

#Preview {
    CPUMonitorView()
}
