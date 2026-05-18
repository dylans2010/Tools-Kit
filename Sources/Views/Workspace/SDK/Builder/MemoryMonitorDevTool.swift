import SwiftUI

struct MemoryMonitorDevTool: DevTool {
    let id = "memory-monitor"
    let name = "Memory Monitor"
    let category = DevToolCategory.performance
    let icon = "memorychip"
    let description = "Monitor application memory usage"

    func render() -> some View {
        MemoryMonitorView()
    }
}

struct MemoryMonitorView: View {
    @StateObject private var viewModel = MemoryMonitorViewModel()

    var body: some View {
        Form {
            Section("Current Usage") {
                LabeledContent("Resident Memory", value: viewModel.residentMemory)
                LabeledContent("Virtual Memory", value: viewModel.virtualMemory)
            }

            Section("Usage History") {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(viewModel.history.indices, id: \.self) { i in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 4, height: CGFloat(viewModel.history[i]) / 1024.0 / 1024.0 / 2.0)
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

class MemoryMonitorViewModel: ObservableObject {
    @Published var residentMemory = "0 MB"
    @Published var virtualMemory = "0 MB"
    @Published var history: [Int64] = []

    private var timer: Timer?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
    }

    private func update() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            DispatchQueue.main.async {
                self.residentMemory = "\(info.resident_size / 1024 / 1024) MB"
                self.virtualMemory = "\(info.virtual_size / 1024 / 1024) MB"
                self.history.append(Int64(info.resident_size))
                if self.history.count > 50 { self.history.removeFirst() }
            }
        }
    }
}
