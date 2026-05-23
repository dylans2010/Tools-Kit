import SwiftUI

struct Diag_EnergyImpactView: View {
    @State private var energyLevel: EnergyLevel = .low
    @State private var cpuUsage: Double = 0
    @State private var gpuUsage: String = "Idle"
    @State private var networkActivity: String = "Idle"
    @State private var locationUsage: String = "Inactive"
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var history: [EnergySample] = []

    enum EnergyLevel: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"

        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            }
        }

        var icon: String {
            switch self {
            case .low: return "leaf.fill"
            case .moderate: return "bolt.fill"
            case .high: return "flame.fill"
            case .veryHigh: return "exclamationmark.triangle.fill"
            }
        }
    }

    struct EnergySample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: EnergyLevel
        let cpu: Double
    }

    var body: some View {
        Form {
            Section("Energy Impact") {
                HStack {
                    Image(systemName: energyLevel.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(energyLevel.color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(energyLevel.rawValue)
                            .font(.title2.bold())
                            .foregroundStyle(energyLevel.color)
                        Text("Current energy consumption estimate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Breakdown") {
                LabeledContent("CPU") {
                    HStack {
                        Text(String(format: "%.1f%%", cpuUsage))
                            .monospacedDigit()
                        impactIndicator(cpuUsage > 50 ? .high : (cpuUsage > 20 ? .moderate : .low))
                    }
                }
                LabeledContent("GPU") {
                    HStack {
                        Text(gpuUsage)
                        impactIndicator(gpuUsage == "Active" ? .moderate : .low)
                    }
                }
                LabeledContent("Network") {
                    HStack {
                        Text(networkActivity)
                        impactIndicator(networkActivity != "Idle" ? .moderate : .low)
                    }
                }
                LabeledContent("Location") {
                    HStack {
                        Text(locationUsage)
                        impactIndicator(locationUsage == "Active" ? .high : .low)
                    }
                }
                LabeledContent("Display") {
                    HStack {
                        Text(String(format: "%.0f%%", UIScreen.main.brightness * 100))
                        impactIndicator(UIScreen.main.brightness > 0.7 ? .moderate : .low)
                    }
                }
                LabeledContent("Thermal") {
                    HStack {
                        Text(thermalLabel)
                        impactIndicator(thermalImpact)
                    }
                }
            }

            Section("Power Saving Tips") {
                if UIScreen.main.brightness > 0.7 {
                    tip(icon: "sun.max", text: "Reduce screen brightness to save power")
                }
                if !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    tip(icon: "bolt.circle", text: "Enable Low Power Mode for extended battery")
                }
                if cpuUsage > 50 {
                    tip(icon: "cpu", text: "High CPU usage is draining battery faster")
                }
                tip(icon: "wifi", text: "WiFi uses less power than cellular data")
            }

            if !history.isEmpty {
                Section("History") {
                    ForEach(history.suffix(10)) { sample in
                        HStack {
                            Circle()
                                .fill(sample.level.color)
                                .frame(width: 8, height: 8)
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(sample.level.rawValue)
                                .font(.caption)
                                .foregroundStyle(sample.level.color)
                            Text(String(format: "CPU: %.0f%%", sample.cpu))
                                .font(.caption2.monospacedDigit())
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
        .navigationTitle("Energy Impact")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshMetrics(); startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    @ViewBuilder
    private func impactIndicator(_ level: EnergyLevel) -> some View {
        Circle()
            .fill(level.color)
            .frame(width: 8, height: 8)
    }

    @ViewBuilder
    private func tip(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.caption)
        }
    }

    private var thermalLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalImpact: EnergyLevel {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .low
        case .fair: return .moderate
        case .serious: return .high
        case .critical: return .veryHigh
        @unknown default: return .low
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            refreshMetrics()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshMetrics() {
        cpuUsage = getCPUUsage()

        // Determine energy level
        if cpuUsage > 60 || ProcessInfo.processInfo.thermalState == .serious {
            energyLevel = .veryHigh
        } else if cpuUsage > 30 || ProcessInfo.processInfo.thermalState == .fair {
            energyLevel = .high
        } else if cpuUsage > 10 || UIScreen.main.brightness > 0.8 {
            energyLevel = .moderate
        } else {
            energyLevel = .low
        }

        history.append(EnergySample(timestamp: Date(), level: energyLevel, cpu: cpuUsage))
        if history.count > 60 { history.removeFirst() }
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
        return totalUsage
    }
}
