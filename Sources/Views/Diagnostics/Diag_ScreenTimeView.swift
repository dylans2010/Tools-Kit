import SwiftUI

struct Diag_ScreenTimeView: View {
    @State private var screenBrightness: CGFloat = 0
    @State private var uptime: TimeInterval = 0
    @State private var idleTimerDisabled = false

    var body: some View {
        Form {
            Section("Screen Time") {
                VStack(spacing: 12) {
                    Image(systemName: "hourglass.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)
                    Text("Session Info")
                        .font(.headline)
                    Text("Current screen session details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Display") {
                LabeledContent("Screen Brightness") {
                    Text("\(Int(screenBrightness * 100))%").monospacedDigit()
                }
                LabeledContent("Auto-Lock Disabled") {
                    Text(idleTimerDisabled ? "Yes" : "No")
                        .foregroundStyle(idleTimerDisabled ? .orange : .green)
                }
            }

            Section("Session") {
                LabeledContent("System Uptime") {
                    Text(formattedUptime).monospacedDigit()
                }
                LabeledContent("Process Uptime") {
                    Text(formattedProcessUptime).monospacedDigit()
                }
                LabeledContent("Active Processors") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                }
            }

            Section("Power State") {
                LabeledContent("Low Power Mode") {
                    let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled
                    Text(lpm ? "Enabled" : "Disabled")
                        .foregroundStyle(lpm ? .yellow : .green)
                }
                LabeledContent("Thermal State") {
                    Text(thermalStateText)
                        .foregroundStyle(thermalColor)
                }
            }

            Section {
                Button("Refresh") { loadData() }
            }
        }
        .navigationTitle("Screen Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
    }

    private func loadData() {
        screenBrightness = UIScreen.main.brightness
        uptime = ProcessInfo.processInfo.systemUptime
        idleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
    }

    private var formattedUptime: String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var formattedProcessUptime: String {
        let t = ProcessInfo.processInfo.systemUptime
        let hours = Int(t) / 3600
        let minutes = (Int(t) % 3600) / 60
        let seconds = Int(t) % 60
        return "\(hours)h \(minutes)m \(seconds)s"
    }

    private var thermalStateText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }
}
