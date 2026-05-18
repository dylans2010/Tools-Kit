import SwiftUI

struct DeviceInfoDevTool: DevTool {
    let id = "device-info"
    let name = "Device Info"
    let category = DevToolCategory.system
    let icon = "iphone"
    let description = "Detailed hardware and software info"

    func render() -> some View {
        DeviceInfoView()
    }
}

struct DeviceInfoView: View {
    @StateObject private var viewModel = DeviceInfoViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Device Info",
                description: "Comprehensive overview of the current hardware specifications and system environment.",
                icon: "iphone"
            )
            .padding()

            Form {
                Section("Hardware") {
                    LabeledContent("Model", value: viewModel.model)
                    LabeledContent("Processor", value: "\(ProcessInfo.processInfo.processorCount) Cores")
                    LabeledContent("Physical Memory", value: viewModel.memory)
                }

                Section("Software") {
                    LabeledContent("System Name", value: UIDevice.current.systemName)
                    LabeledContent("System Version", value: UIDevice.current.systemVersion)
                    LabeledContent("Language", value: Locale.current.language.languageCode?.identifier ?? "Unknown")
                }
            }
        }
    }
}

class DeviceInfoViewModel: ObservableObject {
    var model: String = UIDevice.current.model
    var memory: String = ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)
}
