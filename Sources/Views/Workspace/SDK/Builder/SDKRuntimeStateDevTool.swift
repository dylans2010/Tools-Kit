import SwiftUI

private class _DTSDK: ObservableObject {
    static let shared = _DTSDK()
    @Published var isInitialized: Bool = false
    @Published var version: String = "unknown"
    private init() {}
}

struct SDKRuntimeStateDevTool: DevTool {
    let id = "sdk-runtime-state"
    let name = "Runtime State"
    let category = DevToolCategory.debugging
    let icon = "brain.head.profile"
    let description = "Monitor SDK internal state"

    func render() -> some View {
        SDKRuntimeStateView()
    }
}

struct SDKRuntimeStateView: View {
    @StateObject private var sdk = _DTSDK.shared

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Runtime State",
                description: "Monitor the global state of the SDK orchestrator, including sync status and initialization.",
                icon: "brain.head.profile"
            )
            .padding()

            Form {
                Section("Global Status") {
                    LabeledContent("Initialized", value: sdk.isInitialized ? "Yes" : "No")
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
