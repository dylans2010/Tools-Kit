import SwiftUI
struct PortCheckerView: View {
    @StateObject private var backend = PortCheckerBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Check") {
                backend.check()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Port Checker")
    }
}
struct PortCheckerTool: Tool {
    let name = "Port Checker"
    let icon = "server.rack"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Port Checker"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 3
    var view: AnyView { AnyView(PortCheckerView()) }
}
