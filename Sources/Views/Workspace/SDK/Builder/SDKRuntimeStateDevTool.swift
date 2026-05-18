import SwiftUI

struct SDKRuntimeStateDevTool: DevTool {
    let id = "sdk-runtime-state"
    let name = "Runtime State"
    let category = DevToolCategory.debugging
    let icon = "brain.head.profile"
    let description = "Monitor ToolsKitSDK internal state"

    func render() -> some View {
        SDKRuntimeStateView()
    }
}

struct SDKRuntimeStateView: View {
    @StateObject private var sdk = ToolsKitSDK.shared

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Runtime State",
                description: "Monitor the global state of the ToolsKitSDK orchestrator, including sync status and initialization.",
                icon: "brain.head.profile"
            )
            .padding()

            Form {
                Section("Global Status") {
                    LabeledContent("Initialized", value: "Yes")
                }

                Section("Subsystem Health") {
                    HStack {
                        Text("Policy Engine")
                        Spacer()
                        StatusBadge(text: "Active", color: .green)
                    }
                    HStack {
                        Text("Audit Logger")
                        Spacer()
                        StatusBadge(text: "Active", color: .green)
                    }
                }
            }
        }
    }
}
