import SwiftUI

struct Diag_BatteryHealthView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var batteryLevel: Float = 0
    @State private var batteryState: String = "Unknown"

    var body: some View {
        Form {
            Section("Battery Level") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0, batteryLevel)))
                            .stroke(batteryColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: batteryLevel)

                        VStack {
                            Image(systemName: batteryIcon)
                                .font(.title)
                                .foregroundStyle(batteryColor)
                            Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A")
                                .font(.title2.monospacedDigit().bold())
                        }
                    }
                    .frame(width: 150, height: 150)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Status") {
                LabeledContent("Battery State") { Text(batteryState) }
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "Unavailable")
                        .monospacedDigit()
                }
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .orange : .green)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "battery.100")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Battery Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            service.enableBatteryMonitoring()
            refreshBattery()
        }
        .onDisappear { stopMonitoring() }
    }

    private var batteryColor: Color {
        if batteryLevel > 0.5 { return .green }
        if batteryLevel > 0.2 { return .yellow }
        return .red
    }

    private var batteryIcon: String {
        if batteryState == "Charging" { return "bolt.fill" }
        if batteryLevel > 0.75 { return "battery.100" }
        if batteryLevel > 0.5 { return "battery.75" }
        if batteryLevel > 0.25 { return "battery.50" }
        return "battery.25"
    }

    private func refreshBattery() {
        batteryLevel = service.batteryLevel
        batteryState = service.batteryState
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refreshBattery()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
