import SwiftUI

struct OSVersionInspectorDevTool: DevTool {
    let id = "os-version-inspector"
    let name = "OS Version Inspector"
    let category = DevToolCategory.system
    let icon = "info.bubble"
    let description = "View OS version and build"

    func render() -> some View {
        OSVersionInspectorView()
    }
}

struct OSVersionInspectorView: View {
    var body: some View {
        List {
            Section("OS Details") {
                LabeledContent("Version", value: UIDevice.current.systemVersion)
                LabeledContent("Kernel", value: "Darwin")
            }
        }
    }
}
