import SwiftUI

struct AppStateInspectorDevTool: DevTool {
    let id = "app-state-inspector"
    let name = "App State Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "sidebar.left"
    let description = "Inspect current application state"

    func render() -> some View {
        AppStateInspectorView()
    }
}

struct AppStateInspectorView: View {
    var body: some View {
        List {
            Section("App Lifecycle") {
                LabeledContent("State", value: stateDescription)
                LabeledContent("Is Multitasking", value: UIDevice.current.isGeneratingDeviceOrientationNotifications ? "Yes" : "No")
            }

            Section("Hardware") {
                LabeledContent("Proximity", value: UIDevice.current.isProximityMonitoringEnabled ? "Enabled" : "Disabled")
                LabeledContent("Battery", value: "\(Int(UIDevice.current.batteryLevel * 100))%")
            }
        }
    }

    var stateDescription: String {
        switch UIApplication.shared.applicationState {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
}
