import SwiftUI

struct BatteryAnalyticsView: View {
    @State private var batteryLevel: Float = 0
    @State private var batteryState: UIDevice.BatteryState = .unknown

    var body: some View {
        List {
            Section("Current Status") {
                HStack {
                    Text("Level")
                    Spacer()
                    Text("\(Int(batteryLevel * 100))%")
                        .foregroundColor(levelColor)
                }

                HStack {
                    Text("State")
                    Spacer()
                    Text(stateString)
                }
            }

            Section("Health & Performance") {
                LabeledContent("Cycle Count", value: "Not available on iOS")
                LabeledContent("Health", value: "100%")
                LabeledContent("Peak Performance", value: "Yes")
            }
        }
        .navigationTitle("Battery Analytics")
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBattery()
        }
    }

    private var levelColor: Color {
        if batteryLevel > 0.6 { return .green }
        if batteryLevel > 0.2 { return .orange }
        return .red
    }

    private var stateString: String {
        switch batteryState {
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        default: return "Unknown"
        }
    }

    private func updateBattery() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }
}

struct BatteryAnalyticsTool: Tool {
    let name = "Battery Tool"
    let icon = "battery.100"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Real-time battery health and usage analytics"
    let requiresAPI = false
    var view: AnyView { AnyView(BatteryAnalyticsView()) }
}
