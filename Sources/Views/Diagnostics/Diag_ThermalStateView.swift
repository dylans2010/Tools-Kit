import SwiftUI

struct Diag_ThermalStateView: View {
    @State private var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var history: [String] = []

    var body: some View {
        Form {
            Section("Current Thermal State") {
                VStack(spacing: 12) {
                    Image(systemName: thermalIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(thermalColor)
                        .symbolEffect(.pulse, isActive: isMonitoring)

                    Text(thermalLabel)
                        .font(.title2.bold())
                        .foregroundStyle(thermalColor)

                    Text(thermalDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Thermal Scale") {
                VStack(spacing: 8) {
                    ThermalScaleRow(label: "Nominal", color: .green, isActive: thermalState == .nominal)
                    ThermalScaleRow(label: "Fair", color: .yellow, isActive: thermalState == .fair)
                    ThermalScaleRow(label: "Serious", color: .orange, isActive: thermalState == .serious)
                    ThermalScaleRow(label: "Critical", color: .red, isActive: thermalState == .critical)
                }
            }

            Section("System") {
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .orange : .green)
                }
                LabeledContent("Active Cores") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount) / \(ProcessInfo.processInfo.processorCount)")
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "thermometer.medium")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Thermal State")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private var thermalIcon: String {
        switch thermalState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "thermometer.sun.fill"
        @unknown default: return "thermometer.medium"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    private var thermalLabel: String {
        switch thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalDescription: String {
        switch thermalState {
        case .nominal: return "Device temperature is within normal operating range."
        case .fair: return "Temperature is slightly elevated. Performance may be slightly reduced."
        case .serious: return "Temperature is high. System is actively throttling performance."
        case .critical: return "Temperature is critically high. Immediate performance reduction in effect."
        @unknown default: return "Unable to determine thermal state."
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}

private struct ThermalScaleRow: View {
    let label: String
    let color: Color
    let isActive: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay {
                    if isActive {
                        Circle().stroke(color, lineWidth: 2).scaleEffect(1.8).opacity(0.3)
                    }
                }
            Text(label)
                .font(.subheadline)
                .fontWeight(isActive ? .bold : .regular)
            Spacer()
            if isActive {
                Text("Current")
                    .font(.caption)
                    .foregroundStyle(color)
            }
        }
    }
}
