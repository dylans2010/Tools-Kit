import SwiftUI
struct IPInfoView: View {
    @StateObject private var backend = IPInfoBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Fetch") {
                backend.fetch()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("IP Info")
    }
}
struct IPInfoTool: Tool {
    let name = "IP Info"
    let icon = "network"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "IP Info"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(IPInfoView()) }
}
