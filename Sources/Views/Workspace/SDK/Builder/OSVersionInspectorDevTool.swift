import SwiftUI

struct OSVersionInspectorDevTool: DevTool {
    let id = "os-version-inspector"
    let name = "OS Version Inspector"
    let category = DevToolCategory.system
    let icon = "info.bubble"
    let description = "Inspect OS version and build details"

    func render() -> some View {
        OSVersionInspectorView()
    }
}

struct OSVersionInspectorView: View {
    var body: some View {
        Form {
            Section("Operating System") {
                LabeledContent("Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                LabeledContent("Major", value: "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
                LabeledContent("Minor", value: "\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)")
                LabeledContent("Patch", value: "\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)")
            }
        }
    }
}

#Preview {
    OSVersionInspectorView()
}
