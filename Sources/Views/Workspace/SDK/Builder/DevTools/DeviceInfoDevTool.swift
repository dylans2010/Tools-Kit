import SwiftUI

struct DeviceInfoTool: DevTool {
    let id = UUID()
    let name = "Device Info"
    let category: DevToolCategory = .system
    let icon = "iphone"
    let description = "View device hardware and software info"
    func render() -> some View { DeviceInfoDevToolView() }
}

struct DeviceInfoDevToolView: View {
    var body: some View {
        Form {
            Section("Device") {
                LabeledContent("Name", value: UIDevice.current.name)
                LabeledContent("Model", value: UIDevice.current.model)
                LabeledContent("System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                LabeledContent("Identifier", value: deviceIdentifier)
            }
            Section("Hardware") {
                LabeledContent("Processors", value: "\(ProcessInfo.processInfo.processorCount)")
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
                LabeledContent("Physical Memory", value: formatBytes(ProcessInfo.processInfo.physicalMemory))
            }
            Section("Screen") {
                let screen = UIScreen.main
                LabeledContent("Resolution", value: "\(Int(screen.bounds.width))x\(Int(screen.bounds.height))")
                LabeledContent("Scale", value: "\(Int(screen.scale))x")
                LabeledContent("Native Scale", value: String(format: "%.2f", screen.nativeScale))
                LabeledContent("Brightness", value: String(format: "%.0f%%", screen.brightness * 100))
            }
            Section("App") {
                let info = Bundle.main.infoDictionary ?? [:]
                LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "N/A")
                LabeledContent("Version", value: (info["CFBundleShortVersionString"] as? String) ?? "N/A")
                LabeledContent("Build", value: (info["CFBundleVersion"] as? String) ?? "N/A")
            }
            Section("Locale") {
                LabeledContent("Language", value: Locale.current.language.languageCode?.identifier ?? "N/A")
                LabeledContent("Region", value: Locale.current.region?.identifier ?? "N/A")
                LabeledContent("Calendar", value: Calendar.current.identifier.debugDescription)
                LabeledContent("Timezone", value: TimeZone.current.identifier)
            }
        }
        .navigationTitle("Device Info")
    }

    private var deviceIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
