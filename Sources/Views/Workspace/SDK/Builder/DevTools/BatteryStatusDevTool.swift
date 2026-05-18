import SwiftUI

struct BatteryStatusTool: DevTool {
    let id = UUID()
    let name = "Battery Status"
    let category: DevToolCategory = .system
    let icon = "battery.100"
    let description = "Monitor battery level and charging state"
    func render() -> some View { BatteryStatusDevToolView() }
}

struct BatteryStatusDevToolView: View {
    @State private var batteryLevel: Float = 0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Battery") {
                HStack {
                    Image(systemName: batteryIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(batteryColor)
                    VStack(alignment: .leading) {
                        Text("\(Int(batteryLevel * 100))%")
                            .font(.system(.largeTitle, design: .monospaced).bold())
                        Text(batteryStateString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Details") {
                LabeledContent("Level", value: String(format: "%.1f%%", batteryLevel * 100))
                LabeledContent("State", value: batteryStateString)
                LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                LabeledContent("Thermal State", value: thermalString)
            }
            Section("Gauge") {
                ProgressView(value: Double(batteryLevel))
                    .tint(batteryColor)
                    .scaleEffect(y: 2)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Battery Status")
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBattery()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in updateBattery() }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func updateBattery() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    private var batteryStateString: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    private var batteryColor: Color {
        if batteryState == .charging { return .green }
        if batteryLevel < 0.2 { return .red }
        if batteryLevel < 0.5 { return .orange }
        return .green
    }

    private var batteryIcon: String {
        if batteryState == .charging { return "battery.100.bolt" }
        if batteryLevel > 0.75 { return "battery.100" }
        if batteryLevel > 0.5 { return "battery.75" }
        if batteryLevel > 0.25 { return "battery.50" }
        return "battery.25"
    }

    private var thermalString: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
