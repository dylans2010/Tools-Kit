import SwiftUI

struct Diag_ChargingStateView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var chargingState: UIDevice.BatteryState = .unknown
    @State private var batteryLevel: Float = 0

    var body: some View {
        Form {
            Section("Charging Status") {
                VStack(spacing: 16) {
                    Image(systemName: chargingIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(chargingColor)
                        .symbolEffect(.pulse, isActive: chargingState == .charging)

                    Text(chargingLabel)
                        .font(.title2.bold())
                        .foregroundStyle(chargingColor)

                    if batteryLevel >= 0 {
                        Text("\(Int(batteryLevel * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Details") {
                LabeledContent("State") { Text(chargingLabel) }
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A")
                        .monospacedDigit()
                }
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "bolt.circle.fill")
                        Text(isMonitoring ? "Stop" : "Monitor Charging")
                    }
                }
            }
        }
        .navigationTitle("Charging State")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            service.enableBatteryMonitoring()
            refresh()
        }
        .onDisappear { stopMonitoring() }
    }

    private var chargingIcon: String {
        switch chargingState {
        case .charging: return "bolt.fill"
        case .full: return "battery.100.bolt"
        case .unplugged: return "battery.100"
        default: return "questionmark.circle"
        }
    }

    private var chargingColor: Color {
        switch chargingState {
        case .charging: return .green
        case .full: return .blue
        case .unplugged: return .orange
        default: return .secondary
        }
    }

    private var chargingLabel: String {
        switch chargingState {
        case .charging: return "Charging"
        case .full: return "Fully Charged"
        case .unplugged: return "Not Charging"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    private func refresh() {
        chargingState = UIDevice.current.batteryState
        batteryLevel = UIDevice.current.batteryLevel
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refresh()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
