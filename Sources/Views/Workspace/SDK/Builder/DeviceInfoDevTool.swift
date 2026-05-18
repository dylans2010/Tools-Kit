import SwiftUI

struct DeviceInfoDevTool: DevTool {
    let id = "device-info"
    let name = "Device Info"
    let category = DevToolCategory.system
    let icon = "iphone"
    let description = "View hardware and system information"

    func render() -> some View {
        DeviceInfoView()
    }
}

struct DeviceInfoView: View {
    var body: some View {
        List {
            Section("Hardware") {
                LabeledContent("Model", value: UIDevice.current.model)
                LabeledContent("Name", value: UIDevice.current.name)
                LabeledContent("System Name", value: UIDevice.current.systemName)
            }

            Section("Screen") {
                LabeledContent("Scale", value: "\(UIScreen.main.scale)")
                LabeledContent("Bounds", value: "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))")
            }
        }
    }
}
