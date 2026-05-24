import SwiftUI

struct Diag_RAMStressTestView: View {
    @State private var isRunning = false
    @State private var allocatedMB: Int = 0
    @State private var maxReachedMB: Int = 0
    @State private var currentMemoryUsage: UInt64 = 0
    @State private var totalPhysicalMemory: UInt64 = 0
    @State private var memoryPressureLevel: String = "Normal"
    @State private var writeSpeedMBps: Double = 0
    @State private var readSpeedMBps: Double = 0
    @State private var statusText = "Ready"
    @State private var progress: Double = 0
    @State private var history: [(Int, Double, Double)] = []
    @State private var allocations: [Data] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("System Memory") {
                LabeledContent("Physical RAM") {
                    Text(formatBytes(totalPhysicalMemory))
                        .monospacedDigit()
                }
                LabeledContent("App Memory Used") {
                    Text(formatBytes(currentMemoryUsage))
                        .monospacedDigit()
                }
                LabeledContent("Memory Pressure") {
                    Text(memoryPressureLevel)
                        .foregroundStyle(pressureColor)
                }
            }

            Section("Stress Test") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(pressureColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: progress)
                        VStack(spacing: 2) {
                            Text("\(allocatedMB)")
                                .font(.title.monospacedDigit().bold())
                            Text("MB allocated")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 130, height: 130)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                LabeledContent("Max Reached") {
                    Text("\(maxReachedMB) MB")
                        .monospacedDigit()
                }
                LabeledContent("Write Speed") {
                    Text(writeSpeedMBps > 0 ? String(format: "%.1f MB/s", writeSpeedMBps) : "—")
                        .monospacedDigit()
                }
                LabeledContent("Read Speed") {
                    Text(readSpeedMBps > 0 ? String(format: "%.1f MB/s", readSpeedMBps) : "—")
                        .monospacedDigit()
                }
            }

            if !history.isEmpty {
                Section("Allocation History") {
                    ForEach(history.suffix(8).reversed(), id: \.0) { entry in
                        HStack {
                            Text("\(entry.0) MB")
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Text(String(format: "W: %.1f", entry.1))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.blue)
                            Text(String(format: "R: %.1f", entry.2))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.green)
                            Text("MB/s")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isRunning { stopTest() } else { startTest() }
                } label: {
                    HStack {
                        Image(systemName: isRunning ? "stop.circle.fill" : "memorychip")
                        Text(isRunning ? "Stop & Release" : "Start RAM Stress Test")
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Allocates memory in 10MB chunks, writing and reading patterns to test stability. Memory is released when stopped.")
            }
        }
        .navigationTitle("RAM Stress Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            totalPhysicalMemory = ProcessInfo.processInfo.physicalMemory
            updateMemoryUsage()
        }
        .onDisappear {
            stopTest()
        }
    }

    private var pressureColor: Color {
        switch memoryPressureLevel {
        case "Warning": return .yellow
        case "Critical": return .red
        default: return .green
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            currentMemoryUsage = info.resident_size
        }

        let usageRatio = Double(currentMemoryUsage) / Double(totalPhysicalMemory)
        if usageRatio > 0.8 {
            memoryPressureLevel = "Critical"
        } else if usageRatio > 0.6 {
            memoryPressureLevel = "Warning"
        } else {
            memoryPressureLevel = "Normal"
        }
    }

    private func startTest() {
        isRunning = true
        allocatedMB = 0
        history = []
        statusText = "Allocating memory..."

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard isRunning else { return }
            allocateChunk()
            updateMemoryUsage()
        }
    }

    private func allocateChunk() {
        let chunkSize = 10 * 1024 * 1024 // 10MB

        // Write test
        let writeStart = CFAbsoluteTimeGetCurrent()
        var data = Data(count: chunkSize)
        data.withUnsafeMutableBytes { ptr in
            guard let baseAddr = ptr.baseAddress else { return }
            memset(baseAddr, 0xAB, chunkSize)
        }
        let writeElapsed = CFAbsoluteTimeGetCurrent() - writeStart
        let writeMBps = writeElapsed > 0 ? (Double(chunkSize) / (1024 * 1024)) / writeElapsed : 0

        // Read test
        let readStart = CFAbsoluteTimeGetCurrent()
        var checksum: UInt64 = 0
        data.withUnsafeBytes { ptr in
            guard let baseAddr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in stride(from: 0, to: chunkSize, by: 4096) {
                checksum &+= UInt64(baseAddr[i])
            }
        }
        _ = checksum
        let readElapsed = CFAbsoluteTimeGetCurrent() - readStart
        let readMBps = readElapsed > 0 ? (Double(chunkSize) / (1024 * 1024)) / readElapsed : 0

        allocations.append(data)
        allocatedMB += 10
        maxReachedMB = max(maxReachedMB, allocatedMB)
        writeSpeedMBps = writeMBps
        readSpeedMBps = readMBps
        progress = min(Double(allocatedMB) / 500.0, 1.0)
        history.append((allocatedMB, writeMBps, readMBps))
        statusText = "Allocated \(allocatedMB) MB — Write: \(String(format: "%.1f", writeMBps)) MB/s"

        // Auto-stop if memory pressure is too high
        if memoryPressureLevel == "Critical" && allocatedMB > 100 {
            statusText = "Stopped: Memory pressure critical at \(allocatedMB) MB"
            stopTest()
        }
    }

    private func stopTest() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        allocations.removeAll()
        allocatedMB = 0
        progress = 0
        updateMemoryUsage()
        if statusText.hasPrefix("Allocating") {
            statusText = "Test stopped. Memory released."
        }
    }
}
