import SwiftUI

struct DeviceInfoView: View {
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel

    var body: some View {
        List {
            Section("Hardware") {
                LabeledContent("Model", value: UIDevice.current.model)
                LabeledContent("System Name", value: UIDevice.current.systemName)
                LabeledContent("System Version", value: UIDevice.current.systemVersion)
                LabeledContent("Device Name", value: UIDevice.current.name)
            }

            Section("Screen") {
                LabeledContent("Resolution", value: "\(Int(UIScreen.main.nativeBounds.width)) x \(Int(UIScreen.main.nativeBounds.height))")
                LabeledContent("Scale", value: "\(Int(UIScreen.main.scale))x")
                LabeledContent("Brightness", value: "\(Int(UIScreen.main.brightness * 100))%")
            }

            Section("Power") {
                LabeledContent("Battery", value: batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "Unavailable")
            }
        }
        .navigationTitle("Device Info")
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
        }
    }
}

struct DeviceInfoTool: Tool {
    let name = "Device Info"
    let icon = "info.circle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Comprehensive technical specifications of your device"
    let requiresAPI = false
    var view: AnyView { AnyView(DeviceInfoView()) }
}
