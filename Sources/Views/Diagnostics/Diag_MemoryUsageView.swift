import SwiftUI

struct Diag_MemoryUsageView: View {
    @State private var physicalMemory: UInt64 = 0
    @State private var usedMemory: UInt64 = 0
    @State private var freeMemory: UInt64 = 0
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var ramBreakdown: (wired: UInt64, active: UInt64, inactive: UInt64, compressed: UInt64) = (0, 0, 0, 0)

    var body: some View {
        Form {
            Section("Memory Overview") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: memoryUsageRatio)
                            .stroke(usageColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: memoryUsageRatio)

                        VStack {
                            Text("\(Int(memoryUsageRatio * 100))%")
                                .font(.title.monospacedDigit().bold())
                            Text("Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 140, height: 140)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Details") {
                LabeledContent("Total Physical") {
                    Text(formatBytes(physicalMemory))
                        .monospacedDigit()
                }
                LabeledContent("Used") {
                    Text(formatBytes(usedMemory))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                LabeledContent("Free") {
                    Text(formatBytes(freeMemory))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                LabeledContent("App Memory") {
                    Text(formatBytes(appMemoryUsage()))
                        .monospacedDigit()
                }
            }

            Section("Breakdown") {
                VStack(alignment: .leading, spacing: 12) {
                    MemoryBarRow(label: "Wired", value: formatBytes(ramBreakdown.wired), percent: Double(ramBreakdown.wired) / Double(physicalMemory), color: .red)
                    MemoryBarRow(label: "Active", value: formatBytes(ramBreakdown.active), percent: Double(ramBreakdown.active) / Double(physicalMemory), color: .orange)
                    MemoryBarRow(label: "Inactive", value: formatBytes(ramBreakdown.inactive), percent: Double(ramBreakdown.inactive) / Double(physicalMemory), color: .yellow)
                    MemoryBarRow(label: "Compressed", value: formatBytes(ramBreakdown.compressed), percent: Double(ramBreakdown.compressed) / Double(physicalMemory), color: .blue)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Live Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Memory Usage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshMemory() }
        .onDisappear { stopMonitoring() }
    }

    private var memoryUsageRatio: Double {
        guard physicalMemory > 0 else { return 0 }
        return Double(usedMemory) / Double(physicalMemory)
    }

    private var usageColor: Color {
        if memoryUsageRatio > 0.85 { return .red }
        if memoryUsageRatio > 0.7 { return .orange }
        return .green
    }

    private func refreshMemory() {
        physicalMemory = ProcessInfo.processInfo.physicalMemory
        ramBreakdown = DiagnosticsService.shared.ramBreakdown

        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            usedMemory = info.resident_size
            freeMemory = physicalMemory > usedMemory ? physicalMemory - usedMemory : 0
        }
    }

    private func appMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshMemory()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}

struct MemoryBarRow: View {
    let label: String
    let value: String
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                Spacer()
                Text(value)
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: max(0, min(1, percent)))
                .tint(color)
        }
    }
}
