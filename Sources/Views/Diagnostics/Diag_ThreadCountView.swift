import SwiftUI

struct Diag_ThreadCountView: View {
    @State private var threadCount: Int = 0
    @State private var threadDetails: [ThreadDetail] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var peakThreads: Int = 0
    @State private var history: [(Date, Int)] = []

    struct ThreadDetail: Identifiable {
        let id = UUID()
        let index: Int
        let cpuUsage: Double
        let state: String
        let userTime: TimeInterval
        let systemTime: TimeInterval
    }

    var body: some View {
        Form {
            Section("Thread Summary") {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(threadCount)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.blue)
                        Text("Active Threads")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text("\(peakThreads)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                        Text("Peak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            Section("System Info") {
                LabeledContent("CPU Cores") {
                    Text("\(ProcessInfo.processInfo.processorCount)")
                }
                LabeledContent("Active Cores") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                }
                LabeledContent("Main Thread") {
                    Text(Thread.isMainThread ? "Current" : "Background")
                        .foregroundStyle(.green)
                }
                LabeledContent("QoS Class") {
                    Text(qosLabel)
                }
            }

            if !threadDetails.isEmpty {
                Section("Thread Details") {
                    ForEach(threadDetails) { detail in
                        HStack {
                            Text("#\(detail.index)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 30, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(detail.state)
                                    .font(.caption)
                                Text(String(format: "CPU: %.1f%%", detail.cpuUsage))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "U: %.2fs", detail.userTime))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.blue)
                                Text(String(format: "S: %.2fs", detail.systemTime))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            if !history.isEmpty {
                Section("History") {
                    ForEach(Array(history.suffix(10).enumerated()), id: \.offset) { _, entry in
                        HStack {
                            Text(entry.0, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.1) threads")
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
        .navigationTitle("Thread Count")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshThreads(); startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private var qosLabel: String {
        let qos = Thread.current.qualityOfService
        switch qos {
        case .userInteractive: return "User Interactive"
        case .userInitiated: return "User Initiated"
        case .utility: return "Utility"
        case .background: return "Background"
        case .default: return "Default"
        @unknown default: return "Unknown"
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshThreads()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshThreads() {
        var threadsList: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        let result = task_threads(mach_task_self_, &threadsList, &count)
        guard result == KERN_SUCCESS, let threads = threadsList else { return }
        defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(count) * MemoryLayout<thread_act_t>.size)) }

        threadCount = Int(count)
        if threadCount > peakThreads { peakThreads = threadCount }
        history.append((Date(), threadCount))
        if history.count > 60 { history.removeFirst() }

        var details: [ThreadDetail] = []
        for i in 0..<min(Int(count), 20) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &infoCount)
                }
            }
            if kr == KERN_SUCCESS {
                let usage = Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
                let state: String
                switch info.run_state {
                case TH_STATE_RUNNING: state = "Running"
                case TH_STATE_STOPPED: state = "Stopped"
                case TH_STATE_WAITING: state = "Waiting"
                case TH_STATE_UNINTERRUPTIBLE: state = "Uninterruptible"
                case TH_STATE_HALTED: state = "Halted"
                default: state = "Unknown"
                }
                let userTime = TimeInterval(info.user_time.seconds) + TimeInterval(info.user_time.microseconds) / 1_000_000
                let systemTime = TimeInterval(info.system_time.seconds) + TimeInterval(info.system_time.microseconds) / 1_000_000
                details.append(ThreadDetail(index: i, cpuUsage: usage, state: state, userTime: userTime, systemTime: systemTime))
            }
        }
        threadDetails = details
    }
}
