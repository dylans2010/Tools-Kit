import SwiftUI

struct Diag_SystemLoadView: View {
    @State private var cpuUsage: Double = 0
    @State private var threadCount: Int = 0
    @State private var activeProcessorCount: Int = 0
    @State private var totalProcessorCount: Int = 0
    @State private var loadHistory: [LoadSample] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var memoryPressure: String = "Normal"
    @State private var taskCount: Int = 0

    struct LoadSample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let cpuUsage: Double
        let threads: Int
    }

    var body: some View {
        Form {
            Section("CPU") {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: min(cpuUsage / 100, 1.0))
                            .stroke(cpuColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: cpuUsage)
                        VStack {
                            Text(String(format: "%.1f%%", cpuUsage))
                                .font(.title2.monospacedDigit().bold())
                            Text("CPU Usage")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Processor") {
                LabeledContent("Total Cores") { Text("\(totalProcessorCount)") }
                LabeledContent("Active Cores") { Text("\(activeProcessorCount)") }
                LabeledContent("Thread Count") { Text("\(threadCount)") }
                LabeledContent("Task Count") { Text("\(taskCount)") }
                LabeledContent("Memory Pressure") {
                    Text(memoryPressure)
                        .foregroundStyle(memoryPressureColor)
                }
            }

            Section("Thermal") {
                LabeledContent("Thermal State") {
                    Text(thermalStateLabel)
                        .foregroundStyle(thermalStateColor)
                }
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .orange : .green)
                }
            }

            if !loadHistory.isEmpty {
                Section("History (\(loadHistory.count) samples)") {
                    ForEach(loadHistory.suffix(10)) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", sample.cpuUsage))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(sample.cpuUsage > 80 ? .red : (sample.cpuUsage > 50 ? .orange : .green))
                            Text("\(sample.threads) threads")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("System Load")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            totalProcessorCount = ProcessInfo.processInfo.processorCount
            activeProcessorCount = ProcessInfo.processInfo.activeProcessorCount
            refreshStats()
            startMonitoring()
        }
        .onDisappear { stopMonitoring() }
    }

    private var cpuColor: Color {
        if cpuUsage > 80 { return .red }
        if cpuUsage > 50 { return .orange }
        return .green
    }

    private var thermalStateLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalStateColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private var memoryPressureColor: Color {
        switch memoryPressure {
        case "Normal": return .green
        case "Warning": return .orange
        case "Critical": return .red
        default: return .secondary
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshStats()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshStats() {
        cpuUsage = getCPUUsage()
        threadCount = getThreadCount()
        activeProcessorCount = ProcessInfo.processInfo.activeProcessorCount
        taskCount = Thread.isMainThread ? 1 : 0
        taskCount = getTaskCount()

        let sample = LoadSample(timestamp: Date(), cpuUsage: cpuUsage, threads: threadCount)
        loadHistory.append(sample)
        if loadHistory.count > 60 { loadHistory.removeFirst() }

        let memUsed = getMemoryUsedBytes()
        let total = ProcessInfo.processInfo.physicalMemory
        let ratio = Double(memUsed) / Double(total)
        if ratio > 0.9 { memoryPressure = "Critical" }
        else if ratio > 0.7 { memoryPressure = "Warning" }
        else { memoryPressure = "Normal" }
    }

    private func getCPUUsage() -> Double {
        var threadsList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let result = task_threads(mach_task_self_, &threadsList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadsList else { return 0 }
        defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(threadCount) * MemoryLayout<thread_act_t>.size)) }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &infoCount)
                }
            }
            if kr == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }
        return min(totalUsage, Double(ProcessInfo.processInfo.processorCount) * 100)
    }

    private func getThreadCount() -> Int {
        var threadsList: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        let result = task_threads(mach_task_self_, &threadsList, &count)
        if result == KERN_SUCCESS, let threads = threadsList {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(count) * MemoryLayout<thread_act_t>.size))
        }
        return Int(count)
    }

    private func getTaskCount() -> Int {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), intPtr, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(taskInfo.suspend_count) + 1 : 1
    }

    private func getMemoryUsedBytes() -> UInt64 {
        var info = task_vm_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        return result == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
    }
}
