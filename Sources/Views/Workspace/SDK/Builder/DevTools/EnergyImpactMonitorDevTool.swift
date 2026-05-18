import SwiftUI

struct EnergyImpactMonitorTool: DevTool {
    let id = UUID()
    let name = "Energy Impact Monitor"
    let category: DevToolCategory = .performance
    let icon = "bolt.fill"
    let description = "Monitor energy usage and thermal state"
    func render() -> some View { EnergyImpactMonitorDevToolView() }
}

struct EnergyImpactMonitorDevToolView: View {
    @State private var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @State private var isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Thermal State") {
                HStack {
                    Image(systemName: thermalIcon)
                        .font(.largeTitle)
                        .foregroundStyle(thermalColor)
                    VStack(alignment: .leading) {
                        Text(thermalString).font(.title2.bold())
                        Text("Current thermal pressure").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Power") {
                LabeledContent("Low Power Mode") {
                    HStack {
                        Circle().fill(isLowPower ? Color.yellow : Color.green).frame(width: 8, height: 8)
                        Text(isLowPower ? "Enabled" : "Disabled")
                    }
                }
            }
            Section("Thermal Scale") {
                ForEach(["Nominal", "Fair", "Serious", "Critical"], id: \.self) { level in
                    HStack {
                        Circle()
                            .fill(level == thermalString ? thermalColor : Color.gray.opacity(0.2))
                            .frame(width: 12, height: 12)
                        Text(level)
                        Spacer()
                        if level == thermalString {
                            Text("Current").font(.caption).foregroundStyle(.accent)
                        }
                    }
                }
            }
            Section("Recommendations") {
                if thermalState == .serious || thermalState == .critical {
                    Label("Reduce background processing", systemImage: "exclamationmark.triangle")
                    Label("Pause non-essential animations", systemImage: "exclamationmark.triangle")
                    Label("Defer heavy computations", systemImage: "exclamationmark.triangle")
                } else {
                    Label("System is running normally", systemImage: "checkmark.circle")
                }
            }
            .font(.caption)
        }
        .navigationTitle("Energy Impact Monitor")
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                thermalState = ProcessInfo.processInfo.thermalState
                isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var thermalString: String {
        switch thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
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
    private var thermalIcon: String {
        switch thermalState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "thermometer.sun.fill"
        @unknown default: return "thermometer"
        }
    }
}
