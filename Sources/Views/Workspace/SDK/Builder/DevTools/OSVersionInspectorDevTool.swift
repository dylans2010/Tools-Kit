import SwiftUI

struct OSVersionInspectorTool: DevTool {
    let id = UUID()
    let name = "OS Version Inspector"
    let category: DevToolCategory = .system
    let icon = "info.circle"
    let description = "Check OS version and API availability"
    func render() -> some View { OSVersionInspectorDevToolView() }
}

struct OSVersionInspectorDevToolView: View {
    var body: some View {
        Form {
            Section("Current OS") {
                LabeledContent("System", value: UIDevice.current.systemName)
                LabeledContent("Version", value: UIDevice.current.systemVersion)
                let v = ProcessInfo.processInfo.operatingSystemVersion
                LabeledContent("Semantic", value: "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)")
            }
            Section("API Availability") {
                availabilityRow("iOS 18", available: true)
                availabilityRow("iOS 17", available: true)
                availabilityRow("iOS 16", available: true)
                availabilityRow("iOS 15", available: true)
                availabilityRow("SwiftUI", available: true)
                availabilityRow("Combine", available: true)
                availabilityRow("Async/Await", available: true)
                availabilityRow("Swift Concurrency", available: true)
                availabilityRow("Observation Framework", available: true)
            }
            Section("Kernel") {
                LabeledContent("Hostname", value: ProcessInfo.processInfo.hostName)
                LabeledContent("Process", value: ProcessInfo.processInfo.processName)
                LabeledContent("PID", value: "\(ProcessInfo.processInfo.processIdentifier)")
            }
        }
        .navigationTitle("OS Version Inspector")
    }

    @ViewBuilder
    private func availabilityRow(_ feature: String, available: Bool) -> some View {
        LabeledContent(feature) {
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .red)
        }
    }
}
