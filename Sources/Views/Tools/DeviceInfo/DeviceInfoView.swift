import SwiftUI

struct DeviceInfoView: View {
    @StateObject private var backend = DeviceInfoBackend()

    var body: some View {
        ToolDetailView(tool: DeviceInfoTool()) {
            ToolInputSection("System Information") {
                ForEach(backend.info) { item in
                    HStack {
                        Text(item.key)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(item.value)
                            .bold()
                            .textSelection(.enabled)
                    }
                    .padding()
                    if item.id != backend.info.last?.id {
                        Divider()
                    }
                }
            }
        }
        .onAppear {
            backend.refreshInfo()
        }
    }
}

struct DeviceInfoTool: Tool {
    let name = "Device Info"
    let icon = "info.circle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Detailed hardware and software information about your device"
    let requiresAPI = false
    var view: AnyView { AnyView(DeviceInfoView()) }
}
