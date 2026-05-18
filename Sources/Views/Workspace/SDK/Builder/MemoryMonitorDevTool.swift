import SwiftUI

struct MemoryMonitorDevTool: DevTool {
    let id = "memory-monitor"
    let name = "Memory Monitor"
    let category = DevToolCategory.performance
    let icon = "memorychip"
    let description = "Real-time memory allocation monitoring"

    func render() -> some View {
        MemoryMonitorView()
    }
}

struct MemoryMonitorView: View {
    @StateObject private var viewModel = MemoryMonitorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Memory Monitor",
                description: "Track application memory footprint, including heap allocation and resident set size.",
                icon: "memorychip"
            )
            .padding()

            VStack {
                UsageChart(data: viewModel.usageHistory)
                    .frame(height: 200)
                    .padding()

                Form {
                    Section("Usage") {
                        LabeledContent("Current", value: viewModel.currentMemory)
                        LabeledContent("Peak", value: viewModel.peakMemory)
                    }

                    Section("System") {
                        LabeledContent("Physical Memory", value: viewModel.totalMemory)
                    }
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

class MemoryMonitorViewModel: ObservableObject {
    @Published var currentMemory = "0 MB"
    @Published var peakMemory = "0 MB"
    @Published var totalMemory = "0 GB"
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 50)

    private var timer: Timer?
    private var peakBytes: Int64 = 0

    func start() {
        let physical = ProcessInfo.processInfo.physicalMemory
        totalMemory = ByteCountFormatter.string(fromByteCount: Int64(physical), countStyle: .memory)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
    }

    private func update() {
        // Fetch real memory info
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = Int64(taskInfo.resident_size)
            currentMemory = ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .memory)

            if usedBytes > peakBytes {
                peakBytes = usedBytes
                peakMemory = currentMemory
            }

            let percent = Double(usedBytes) / Double(ProcessInfo.processInfo.physicalMemory) * 1000 // Scaled for visibility
            usageHistory.removeFirst()
            usageHistory.append(percent)
        }
    }
}
