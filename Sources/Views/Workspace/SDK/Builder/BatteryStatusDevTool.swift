import SwiftUI

struct BatteryStatusDevTool: DevTool {
    let id = "battery-status"
    let name = "Battery Status"
    let category = DevToolCategory.system
    let icon = "battery.100"
    let description = "View battery level and state"

    func render() -> some View {
        BatteryStatusView()
    }
}

struct BatteryStatusView: View {
    @State private var level = UIDevice.current.batteryLevel
    @State private var state = UIDevice.current.batteryState

    var body: some View {
        Form {
            Section("Battery Info") {
                LabeledContent("Level", value: "\(Int(level * 100))%")
                LabeledContent("State", value: stateString)
            }
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            level = UIDevice.current.batteryLevel
            state = UIDevice.current.batteryState
        }
    }

    var stateString: String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
}
