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
        Form {
            Section("Global Status") {
                LabeledContent("Initialized", value: sdk.isInitialized ? "Yes" : "No")
            }

            Section("Subsystem Health") {
                HStack {
                    Text("Policy Engine")
                    Spacer()
                    Text("Active")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("Audit Logger")
                    Spacer()
                    Text("Active")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

#Preview {
    SDKRuntimeStateView()
}
