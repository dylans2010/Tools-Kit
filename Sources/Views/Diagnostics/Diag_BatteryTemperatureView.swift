import SwiftUI

struct Diag_BatteryTemperatureView: View {
    @State private var thermalState: ProcessInfo.ThermalState = .nominal
    @State private var thermalHistory: [(Date, ProcessInfo.ThermalState)] = []
    @State private var batteryLevel: Float = -1
    @State private var isMonitoring = false
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Thermal Status") {
                VStack(spacing: 12) {
                    Image(systemName: thermalIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(thermalColor)
                        .symbolEffect(.pulse, isActive: thermalState == .serious || thermalState == .critical)
                    Text(thermalTitle)
                        .font(.headline)
                    Text(thermalDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current Readings") {
                LabeledContent("Thermal State") {
                    Text(thermalStateString)
                        .foregroundStyle(thermalColor)
                }
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "Unknown")
                        .monospacedDigit()
                }
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .orange : .green)
                }
                LabeledContent("CPU Cores Active") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)/\(ProcessInfo.processInfo.processorCount)")
                        .monospacedDigit()
                }
            }

            if !thermalHistory.isEmpty {
                Section("Thermal History") {
                    ForEach(thermalHistory.suffix(15), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time)
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Circle()
                                .fill(colorFor(entry.1))
                                .frame(width: 10, height: 10)
                            Text(stringFor(entry.1))
                                .font(.caption)
                                .foregroundStyle(colorFor(entry.1))
                        }
                    }
                }
            }

            Section("Temperature Levels") {
                VStack(alignment: .leading, spacing: 8) {
                    ThermalLevelRow(level: "Nominal", description: "Normal operating temperature", color: .green)
                    ThermalLevelRow(level: "Fair", description: "Slightly elevated, normal under load", color: .yellow)
                    ThermalLevelRow(level: "Serious", description: "Device may begin throttling", color: .orange)
                    ThermalLevelRow(level: "Critical", description: "Device will throttle aggressively", color: .red)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    isMonitoring ? stopMonitoring() : startMonitoring()
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Battery Temperature")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refresh()
        }
        .onDisappear { stopMonitoring() }
    }

    private var thermalIcon: String {
        switch thermalState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "flame.fill"
        @unknown default: return "thermometer.medium"
        }
    }

    private var thermalColor: Color { colorFor(thermalState) }
    private var thermalTitle: String { stringFor(thermalState) }
    private var thermalStateString: String { stringFor(thermalState) }

    private var thermalDescription: String {
        switch thermalState {
        case .nominal: return "Device temperature is within normal operating range"
        case .fair: return "Slightly elevated — normal during heavy use"
        case .serious: return "Device is getting hot — performance may be reduced"
        case .critical: return "Device is overheating — immediate action recommended"
        @unknown default: return "Unknown thermal state"
        }
    }

    private func colorFor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private func stringFor(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func refresh() {
        thermalState = ProcessInfo.processInfo.thermalState
        batteryLevel = UIDevice.current.batteryLevel
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            refresh()
            thermalHistory.append((Date(), thermalState))
            if thermalHistory.count > 100 {
                thermalHistory.removeFirst()
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}

private struct ThermalLevelRow: View {
    let level: String
    let description: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(level)
                    .font(.caption.weight(.medium))
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
