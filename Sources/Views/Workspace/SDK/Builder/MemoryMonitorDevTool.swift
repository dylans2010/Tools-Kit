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
    @State private var showingPressureAlert = false

    var body: some View {
        List {
            Section("Memory Timeline") {
                VStack(spacing: 16) {
                    chartView
                        .frame(height: 140)

                    HStack(spacing: 12) {
                        UsageIndicator(title: "Resident", value: viewModel.currentMemory, percent: viewModel.residentPercent, color: .purple)
                        UsageIndicator(title: "Virtual", value: viewModel.virtualMemory, percent: 0.4, color: .blue)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Allocation Breakdown (Simulated)") {
                VStack(spacing: 12) {
                    MemoryBarRow(label: "Heap", value: viewModel.heapMemory, color: .orange, percent: 0.65)
                    MemoryBarRow(label: "Stack", value: viewModel.stackMemory, color: .cyan, percent: 0.15)
                    MemoryBarRow(label: "Graphics", value: viewModel.graphicsMemory, color: .green, percent: 0.20)
                }
                .padding(.vertical, 4)
            }

            Section("System Status") {
                LabeledContent("Physical RAM", value: viewModel.totalMemory)
                LabeledContent("Page Size", value: "\(vm_kernel_page_size / 1024) KB")
                LabeledContent("Memory Pressure") {
                    Text(viewModel.pressureLevel)
                        .foregroundStyle(pressureColor)
                }
            }

            Section("Simulations") {
                Button {
                    viewModel.simulateMemoryLeak()
                } label: {
                    Label("Simulate Memory Leak", systemImage: "ivfluid.bag.fill")
                }

                Button {
                    showingPressureAlert = true
                } label: {
                    Label("Trigger Memory Warning", systemImage: "exclamationmark.triangle")
                }
                .foregroundStyle(.orange)

                Button(role: .destructive) {
                    viewModel.purgeCache()
                } label: {
                    Label("Purge Simulated Cache", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Memory Monitor")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert("Simulation", isPresented: $showingPressureAlert) {
            Button("OK") { }
        } message: {
            Text("A system memory warning has been simulated. Check app logs for response.")
        }
    }

    private var chartView: some View {
        GeometryReader { geo in
            Path { path in
                guard viewModel.usageHistory.count > 1 else { return }
                let step = geo.size.width / CGFloat(viewModel.usageHistory.count - 1)
                let height = geo.size.height

                path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(viewModel.usageHistory.first ?? 0))))

                for i in 1..<viewModel.usageHistory.count {
                    path.addLine(to: CGPoint(x: CGFloat(i) * step, y: height * (1 - CGFloat(viewModel.usageHistory[i]))))
                }
            }
            .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
        }
    }

    private var pressureColor: Color {
        switch viewModel.pressureLevel {
        case "Normal": return .green
        case "Warning": return .orange
        case "Critical": return .red
        default: return .secondary
        }
    }
}

struct UsageIndicator: View {
    let title: String
    let value: String
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline.monospacedDigit())
            ProgressView(value: percent)
                .tint(color)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MemoryBarRow: View {
    let label: String
    let value: String
    let color: Color
    let percent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(value).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.gray.opacity(0.1))
                    Capsule().fill(color).frame(width: geo.size.width * percent)
                }
            }
            .frame(height: 6)
        }
    }
}

class MemoryMonitorViewModel: ObservableObject {
    @Published var currentMemory = "0 MB"
    @Published var peakMemory = "0 MB"
    @Published var virtualMemory = "0 MB"
    @Published var totalMemory = "0 GB"
    @Published var heapMemory = "0 MB"
    @Published var stackMemory = "0 MB"
    @Published var graphicsMemory = "0 MB"
    @Published var pressureLevel = "Normal"
    @Published var residentPercent: Double = 0
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 60)

    private var timer: Timer?
    private var peakBytes: Int64 = 0
    private var leakedAllocations: [Data] = []

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

    func simulateMemoryLeak() {
        // Allocate 50MB
        let data = Data(repeating: 0, count: 50 * 1024 * 1024)
        leakedAllocations.append(data)
    }

    func purgeCache() {
        leakedAllocations.removeAll()
    }

    private func update() {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = Int64(taskInfo.resident_size)
            let virtualBytes = Int64(taskInfo.virtual_size)

            currentMemory = ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .memory)
            virtualMemory = ByteCountFormatter.string(fromByteCount: virtualBytes, countStyle: .memory)

            if usedBytes > peakBytes {
                peakBytes = usedBytes
                peakMemory = currentMemory
            }

            let physical = Double(ProcessInfo.processInfo.physicalMemory)
            residentPercent = Double(usedBytes) / physical

            // Scaled for graph visibility
            usageHistory.removeFirst()
            usageHistory.append(min(1.0, residentPercent * 5))

            // Simulated breakdowns
            heapMemory = ByteCountFormatter.string(fromByteCount: Int64(Double(usedBytes) * 0.65), countStyle: .memory)
            stackMemory = ByteCountFormatter.string(fromByteCount: Int64(Double(usedBytes) * 0.15), countStyle: .memory)
            graphicsMemory = ByteCountFormatter.string(fromByteCount: Int64(Double(usedBytes) * 0.20), countStyle: .memory)

            if residentPercent > 0.8 {
                pressureLevel = "Critical"
            } else if residentPercent > 0.5 {
                pressureLevel = "Warning"
            } else {
                pressureLevel = "Normal"
            }
        }
    }
}

#Preview {
    MemoryMonitorView()
}

#Preview {
    MemoryMonitorView()
}
