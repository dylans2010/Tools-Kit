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
    @State private var showingExportSheet = false

    var body: some View {
        List {
            Section("System Load") {
                VStack(spacing: 12) {
                    chartView
                        .frame(height: 140)

                    HStack(spacing: 20) {
                        metricBubble(title: "Current", value: String(format: "%.1f%%", viewModel.currentUsage), color: .blue)
                        metricBubble(title: "Peak", value: String(format: "%.1f%%", viewModel.peakUsage), color: .red)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Cores (\(viewModel.coreUsages.count))") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(0..<viewModel.coreUsages.count, id: \.self) { index in
                        CoreUsageView(index: index, usage: viewModel.coreUsages[index])
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Top Processes (Simulated)") {
                ForEach(viewModel.processes) { proc in
                    HStack {
                        Image(systemName: proc.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text(proc.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", proc.cpu))
                            .font(.caption.monospaced())
                            .foregroundStyle(proc.cpu > 20 ? .orange : .secondary)
                    }
                }
            }

            Section("System Diagnostics") {
                LabeledContent("Thermal State", value: viewModel.thermalState)
                LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Active" : "Inactive")
                LabeledContent("Kernel Version", value: viewModel.kernelVersion)
                LabeledContent("Uptime", value: viewModel.uptime)
            }

            Section {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export Load History", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    viewModel.resetPeak()
                } label: {
                    Label("Reset Peak Metrics", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("CPU Monitor")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showingExportSheet) {
            CSVExportView(data: viewModel.usageHistory)
        }
    }

    private var chartView: some View {
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
            .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
        }
    }

    private func metricBubble(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline.monospacedDigit()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CoreUsageView: View {
    let index: Int
    let usage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Core \(index)").font(.caption2).foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(usageColor)
                        .frame(width: geo.size.width * CGFloat(usage / 100))
                }
            }
            .frame(height: 4)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var usageColor: Color {
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .green
    }
}

struct CPUProcess: Identifiable {
    let id = UUID()
    let name: String
    let cpu: Double
    let icon: String
}

class CPUMonitorViewModel: ObservableObject {
    @Published var currentUsage: Double = 0
    @Published var peakUsage: Double = 0
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var coreUsages: [Double] = []
    @Published var thermalState = "Nominal"
    @Published var processes: [CPUProcess] = []
    @Published var uptime = "0s"
    @Published var kernelVersion = "Darwin 23.0.0"

    private var timer: Timer?
    private let startTime = Date()

    init() {
        coreUsages = Array(repeating: 0, count: ProcessInfo.processInfo.processorCount)
        updateKernelInfo()
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
    }

    func resetPeak() {
        peakUsage = 0
    }

    private func update() {
        // CPU Load Calculation
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let totalTicks = Double(cpuLoad.cpu_ticks.0 + cpuLoad.cpu_ticks.1 + cpuLoad.cpu_ticks.2 + cpuLoad.cpu_ticks.3)
            let idleTicks = Double(cpuLoad.cpu_ticks.3)
            let usage = max(0, min(100, (1.0 - (idleTicks / totalTicks)) * 100.0))

            currentUsage = usage
            if usage > peakUsage { peakUsage = usage }

            usageHistory.removeFirst()
            usageHistory.append(usage)

            // Randomize core usages for demo
            for i in 0..<coreUsages.count {
                coreUsages[i] = max(0, min(100, usage + Double.random(in: -15...15)))
            }
        }

        // Simulate processes
        let names = ["Kernel", "ToolsKit", "SpringBoard", "WindowServer", "Backboardd", "MediaServerd"]
        processes = names.map { name in
            CPUProcess(name: name, cpu: Double.random(in: 0.1...15.0), icon: name == "ToolsKit" ? "hammer.fill" : "gearshape")
        }.sorted { $0.cpu > $1.cpu }

        updateThermalState()
        updateUptime()
    }

    private func updateThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }

    private func updateUptime() {
        let diff = Int(Date().timeIntervalSince(startTime))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        uptime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func updateKernelInfo() {
        var size = 0
        sysctlbyname("kern.osrelease", nil, &size, nil, 0)
        var release = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osrelease", &release, &size, nil, 0)
        kernelVersion = "Darwin " + String(cString: release)
    }
}

struct CSVExportView: View {
    let data: [Double]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Load History Export").font(.headline).padding()
                ScrollView {
                    Text(csvString)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                }
                .padding()

                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = csvString
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var csvString: String {
        "Timestamp,CPU_Usage\n" + data.enumerated().map { "\($0),\(String(format: "%.2f", $1))" }.joined(separator: "\n")
    }
}

#Preview {
    CPUMonitorView()
}
