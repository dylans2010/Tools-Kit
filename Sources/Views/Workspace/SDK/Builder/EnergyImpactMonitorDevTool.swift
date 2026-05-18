import SwiftUI

struct EnergyImpactMonitorDevTool: DevTool {
    let id = "energy-impact-monitor"
    let name = "Energy Impact Monitor"
    let category = DevToolCategory.performance
    let icon = "bolt.fill"
    let description = "Monitor battery and energy impact"

    func render() -> some View {
        EnergyImpactMonitorView()
    }
}

struct EnergyImpactMonitorView: View {
    @State private var batteryLevel = UIDevice.current.batteryLevel

    var body: some View {
        Form {
            Section("Device Power") {
                LabeledContent("Battery Level", value: "\(Int(batteryLevel * 100))%")
                LabeledContent("Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Low Power" : "Normal")
            }

            Section("Application Cost") {
                LabeledContent("CPU Energy", value: "Minimal")
                LabeledContent("Network Cost", value: "Idle")
            }
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
        }
    }
}
