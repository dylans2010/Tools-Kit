import SwiftUI
import UIKit

struct Diag_BatteryCycleView: View {
    @State private var batteryLevel: Float = 0
    @State private var batteryState: String = "Unknown"
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var samples: [BatterySample] = []
    @State private var drainRate: Double = 0
    @State private var estimatedTimeRemaining: String = "Calculating..."
    @State private var chargeCount: Int = 0
    @State private var sessionStartLevel: Float = 0
    @State private var sessionStartTime: Date = Date()

    struct BatterySample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: Float
        let state: String
    }

    var body: some View {
        Form {
            Section("Battery Status") {
                HStack(spacing: 16) {
                    VStack {
                        Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(levelColor)
                        Text("Current Level")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Image(systemName: stateIcon)
                            .font(.system(size: 32))
                            .foregroundStyle(stateColor)
                        Text(batteryState)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            Section("Usage Estimation") {
                LabeledContent("Drain Rate") {
                    Text(drainRate != 0 ? String(format: "%.2f%%/hr", drainRate) : "Measuring...")
                        .monospacedDigit()
                        .foregroundStyle(drainRate > 10 ? .red : (drainRate > 5 ? .orange : .green))
                }
                LabeledContent("Time Remaining") {
                    Text(estimatedTimeRemaining)
                        .monospacedDigit()
                }
                LabeledContent("Session Change") {
                    let change = (batteryLevel - sessionStartLevel) * 100
                    Text(String(format: "%+.1f%%", change))
                        .monospacedDigit()
                        .foregroundStyle(change >= 0 ? .green : .red)
                }
                LabeledContent("Session Duration") {
                    Text(formatDuration(Date().timeIntervalSince(sessionStartTime)))
                }
                LabeledContent("Charge Events") {
                    Text("\(chargeCount)")
                }
            }

            Section("Battery Health Indicators") {
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .orange : .green)
                }
                LabeledContent("Thermal State") {
                    Text(thermalStateLabel)
                        .foregroundStyle(thermalStateColor)
                }
                LabeledContent("Optimized Charging") {
                    Text("Managed by iOS")
                        .foregroundStyle(.secondary)
                }
            }

            if !samples.isEmpty {
                Section("Battery History (\(samples.count) samples)") {
                    ForEach(samples.suffix(15)) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(sample.level * 100))%")
                                .font(.caption.monospacedDigit())
                            Text(sample.state)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "battery.100")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Battery Cycle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refreshBattery()
            sessionStartLevel = batteryLevel
            sessionStartTime = Date()
            startMonitoring()
        }
        .onDisappear { stopMonitoring() }
    }

    private var levelColor: Color {
        if batteryLevel > 0.5 { return .green }
        if batteryLevel > 0.2 { return .orange }
        return .red
    }

    private var stateIcon: String {
        switch batteryState {
        case "Charging": return "bolt.fill"
        case "Full": return "battery.100.bolt"
        case "Unplugged": return "battery.75"
        default: return "battery.0"
        }
    }

    private var stateColor: Color {
        switch batteryState {
        case "Charging": return .green
        case "Full": return .blue
        case "Unplugged": return .orange
        default: return .secondary
        }
    }

    private var thermalStateLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Slightly Warm"
        case .serious: return "Hot"
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

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            refreshBattery()
            calculateDrainRate()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshBattery() {
        let prevState = batteryState
        batteryLevel = UIDevice.current.batteryLevel
        switch UIDevice.current.batteryState {
        case .unknown: batteryState = "Unknown"
        case .unplugged: batteryState = "Unplugged"
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        @unknown default: batteryState = "Unknown"
        }

        if prevState != "Charging" && batteryState == "Charging" {
            chargeCount += 1
        }

        samples.append(BatterySample(timestamp: Date(), level: batteryLevel, state: batteryState))
        if samples.count > 200 { samples.removeFirst() }
    }

    private func calculateDrainRate() {
        guard samples.count >= 2 else { return }
        let recent = Array(samples.suffix(10))
        guard let first = recent.first, let last = recent.last else { return }
        let timeDiff = last.timestamp.timeIntervalSince(first.timestamp)
        guard timeDiff > 0 else { return }

        let levelDiff = Double(first.level - last.level) * 100
        drainRate = levelDiff / (timeDiff / 3600)

        if drainRate > 0 && batteryLevel > 0 {
            let hoursRemaining = Double(batteryLevel) * 100 / drainRate
            estimatedTimeRemaining = formatDuration(hoursRemaining * 3600)
        } else if batteryState == "Charging" {
            estimatedTimeRemaining = "Charging..."
        } else {
            estimatedTimeRemaining = "Calculating..."
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
