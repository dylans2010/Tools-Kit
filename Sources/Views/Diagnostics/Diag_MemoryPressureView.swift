import SwiftUI

struct Diag_MemoryPressureView: View {
    @State private var physicalMemory: UInt64 = 0
    @State private var usedMemory: UInt64 = 0
    @State private var freeMemory: UInt64 = 0
    @State private var appMemory: UInt64 = 0
    @State private var compressedMemory: UInt64 = 0
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var peakAppMemory: UInt64 = 0
    @State private var memoryWarnings: Int = 0
    @State private var history: [MemorySample] = []

    struct MemorySample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let appMemory: UInt64
        let systemUsed: UInt64
    }

    var body: some View {
        Form {
            Section("Memory Overview") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: memoryUsageRatio)
                            .stroke(pressureColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: memoryUsageRatio)
                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", memoryUsageRatio * 100))
                                .font(.title2.monospacedDigit().bold())
                            Text("Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    Text(pressureLabel)
                        .font(.headline)
                        .foregroundStyle(pressureColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("System Memory") {
                LabeledContent("Physical RAM") { Text(formatBytes(physicalMemory)) }
                LabeledContent("Used") { Text(formatBytes(usedMemory)).foregroundStyle(.orange) }
                LabeledContent("Free") { Text(formatBytes(freeMemory)).foregroundStyle(.green) }
                LabeledContent("Compressed") { Text(formatBytes(compressedMemory)) }
            }

            Section("App Memory") {
                LabeledContent("Current") { Text(formatBytes(appMemory)).monospacedDigit() }
                LabeledContent("Peak") { Text(formatBytes(peakAppMemory)).monospacedDigit().foregroundStyle(.orange) }
                LabeledContent("Memory Warnings") {
                    Text("\(memoryWarnings)")
                        .foregroundStyle(memoryWarnings > 0 ? .red : .green)
                }
            }

            if !history.isEmpty {
                Section("History") {
                    ForEach(history.suffix(10)) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("App: \(formatBytes(sample.appMemory))")
                                .font(.caption.monospacedDigit())
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
        .navigationTitle("Memory Pressure")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshMemory(); startMonitoring() }
        .onDisappear { stopMonitoring() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            memoryWarnings += 1
        }
    }

    private var memoryUsageRatio: CGFloat {
        guard physicalMemory > 0 else { return 0 }
        return CGFloat(usedMemory) / CGFloat(physicalMemory)
    }

    private var pressureColor: Color {
        let ratio = memoryUsageRatio
        if ratio > 0.9 { return .red }
        if ratio > 0.7 { return .orange }
        return .green
    }

    private var pressureLabel: String {
        let ratio = memoryUsageRatio
        if ratio > 0.9 { return "Critical Pressure" }
        if ratio > 0.7 { return "High Pressure" }
        if ratio > 0.5 { return "Moderate" }
        return "Normal"
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            refreshMemory()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshMemory() {
        physicalMemory = ProcessInfo.processInfo.physicalMemory

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let active = UInt64(vmStats.active_count) * pageSize
            let inactive = UInt64(vmStats.inactive_count) * pageSize
            let wired = UInt64(vmStats.wire_count) * pageSize
            let free = UInt64(vmStats.free_count) * pageSize
            compressedMemory = UInt64(vmStats.compressor_page_count) * pageSize

            usedMemory = active + wired + compressedMemory
            freeMemory = free + inactive
        }

        var taskInfo = task_vm_info()
        var taskCount = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        let taskResult = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(taskCount)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &taskCount)
            }
        }
        if taskResult == KERN_SUCCESS {
            appMemory = UInt64(taskInfo.phys_footprint)
            if appMemory > peakAppMemory { peakAppMemory = appMemory }
        }

        history.append(MemorySample(timestamp: Date(), appMemory: appMemory, systemUsed: usedMemory))
        if history.count > 60 { history.removeFirst() }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
