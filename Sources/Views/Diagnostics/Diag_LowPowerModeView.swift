import SwiftUI

struct Diag_LowPowerModeView: View {
    @State private var isLowPowerMode = false
    @State private var timer: Timer?
    @State private var batteryLevel: Float = 0
    @State private var thermalState: String = "Unknown"

    var body: some View {
        Form {
            Section("Low Power Mode") {
                VStack(spacing: 12) {
                    Image(systemName: isLowPowerMode ? "bolt.circle.fill" : "bolt.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(isLowPowerMode ? .yellow : .green)
                    Text(isLowPowerMode ? "Enabled" : "Disabled")
                        .font(.title2.weight(.semibold))
                    Text(isLowPowerMode ? "Performance is throttled to save battery" : "Device running at full performance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Impact When Enabled") {
                impactRow(icon: "cpu", text: "CPU performance reduced", active: isLowPowerMode)
                impactRow(icon: "arrow.down.circle", text: "Background fetch disabled", active: isLowPowerMode)
                impactRow(icon: "envelope", text: "Mail fetch reduced", active: isLowPowerMode)
                impactRow(icon: "display", text: "Display brightness limited", active: isLowPowerMode)
                impactRow(icon: "sparkles", text: "Visual effects reduced", active: isLowPowerMode)
                impactRow(icon: "icloud", text: "iCloud sync paused", active: isLowPowerMode)
            }

            Section("Device Status") {
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A")
                        .monospacedDigit()
                }
                LabeledContent("Thermal State") {
                    Text(thermalState).foregroundStyle(thermalColor)
                }
            }
        }
        .navigationTitle("Low Power Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { timer?.invalidate() }
    }

    private func impactRow(icon: String, text: String, active: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(active ? .yellow : .secondary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: active ? "exclamationmark.triangle.fill" : "checkmark.circle")
                .foregroundStyle(active ? .yellow : .green)
                .font(.caption)
        }
    }

    private func startMonitoring() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in refresh() }
    }

    private func refresh() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case "Nominal": return .green
        case "Fair": return .yellow
        case "Serious": return .orange
        case "Critical": return .red
        default: return .secondary
        }
    }
}
