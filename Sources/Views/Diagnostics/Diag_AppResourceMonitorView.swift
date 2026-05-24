import SwiftUI
import MachO

struct Diag_AppResourceMonitorView: View {
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var cpuUsage: Double = 0
    @State private var memoryUsage: UInt64 = 0
    @State private var memoryPeak: UInt64 = 0
    @State private var virtualMemory: UInt64 = 0
    @State private var threadCount: Int = 0
    @State private var diskReads: UInt64 = 0
    @State private var diskWrites: UInt64 = 0
    @State private var openFiles: Int = 0
    @State private var cpuHistory: [Double] = []
    @State private var memHistory: [UInt64] = []
    @State private var uptime: TimeInterval = 0
    @State private var loadedImages: Int = 0

    var body: some View {
        Form {
            Section("CPU") {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(cpuUsage / 100.0, 1.0)))
                            .stroke(cpuColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: cpuUsage)
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f%%", cpuUsage))
                                .font(.title3.monospacedDigit().bold())
                            Text("CPU")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)

                    if !cpuHistory.isEmpty {
                        HStack(alignment: .bottom, spacing: 1) {
                            ForEach(cpuHistory.suffix(40).indices, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(cpuHistoryColor(cpuHistory[i]))
                                    .frame(height: CGFloat(cpuHistory[i] / 100.0) * 30)
                            }
                        }
                        .frame(height: 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                LabeledContent("Threads") {
                    Text("\(threadCount)")
                        .monospacedDigit()
                }
            }

            Section("Memory") {
                LabeledContent("Resident") {
                    Text(formatBytes(memoryUsage))
                        .monospacedDigit()
                }
                LabeledContent("Peak") {
                    Text(formatBytes(memoryPeak))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                LabeledContent("Virtual") {
                    Text(formatBytes(virtualMemory))
                        .monospacedDigit()
                }
                LabeledContent("Physical RAM") {
                    Text(formatBytes(ProcessInfo.processInfo.physicalMemory))
                        .monospacedDigit()
                }

                if !memHistory.isEmpty {
                    let maxMem = memHistory.max() ?? 1
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(memHistory.suffix(40).indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.blue)
                                .frame(height: CGFloat(Double(memHistory[i]) / Double(maxMem)) * 30)
                        }
                    }
                    .frame(height: 30)
                }
            }

            Section("Disk & I/O") {
                LabeledContent("Disk Reads") {
                    Text(formatBytes(diskReads))
                        .monospacedDigit()
                }
                LabeledContent("Disk Writes") {
                    Text(formatBytes(diskWrites))
                        .monospacedDigit()
                }
                LabeledContent("Open File Descriptors") {
                    Text("\(openFiles)")
                        .monospacedDigit()
                }
            }

            Section("Process") {
                LabeledContent("PID") {
                    Text("\(ProcessInfo.processInfo.processIdentifier)")
                        .monospacedDigit()
                }
                LabeledContent("Uptime") {
                    Text(String(format: "%.0f s", uptime))
                        .monospacedDigit()
                }
                LabeledContent("Loaded Images") {
                    Text("\(loadedImages)")
                        .monospacedDigit()
                }
                LabeledContent("Active Processors") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                        .monospacedDigit()
                }
                LabeledContent("Thermal State") {
                    Text(thermalStateText)
                        .foregroundStyle(thermalColor)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "chart.bar.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("App Resource Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshData() }
        .onDisappear { stopMonitoring() }
    }

    private var cpuColor: Color {
        if cpuUsage > 80 { return .red }
        if cpuUsage > 50 { return .yellow }
        return .green
    }

    private func cpuHistoryColor(_ value: Double) -> Color {
        if value > 80 { return .red }
        if value > 50 { return .yellow }
        return .green
    }

    private var thermalStateText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func startMonitoring() {
        isMonitoring = true
        cpuHistory = []
        memHistory = []
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshData()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshData() {
        // CPU usage
        cpuUsage = getProcessCPUUsage()
        cpuHistory.append(cpuUsage)

        // Memory
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            memoryUsage = info.resident_size
            virtualMemory = info.virtual_size
            memoryPeak = max(memoryPeak, memoryUsage)
        }
        memHistory.append(memoryUsage)

        // Threads
        var threadList: thread_act_array_t?
        var threadCount_c: mach_msg_type_number_t = 0
        if task_threads(mach_task_self_, &threadList, &threadCount_c) == KERN_SUCCESS {
            threadCount = Int(threadCount_c)
            if let threadList = threadList {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), vm_size_t(threadCount_c) * vm_size_t(MemoryLayout<thread_t>.stride))
            }
        }

        // Open files
        openFiles = countOpenFileDescriptors()

        // Loaded images
        loadedImages = Int(_dyld_image_count())

        // Uptime
        uptime = ProcessInfo.processInfo.systemUptime
    }

    private func getProcessCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount_c: mach_msg_type_number_t = 0

        guard task_threads(mach_task_self_, &threadList, &threadCount_c) == KERN_SUCCESS,
              let threads = threadList else { return 0 }

        var totalUsage: Double = 0

        for i in 0..<Int(threadCount_c) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if result == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount_c) * vm_size_t(MemoryLayout<thread_t>.stride))

        return totalUsage
    }

    private func countOpenFileDescriptors() -> Int {
        var count = 0
        for fd in 0..<256 {
            var statbuf = stat()
            if fstat(Int32(fd), &statbuf) == 0 {
                count += 1
            }
        }
        return count
    }
}
