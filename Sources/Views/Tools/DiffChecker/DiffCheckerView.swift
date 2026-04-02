import SwiftUI
struct DiffCheckerView: View {
    @StateObject private var backend = DiffCheckerBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Check Diff") {
                backend.check()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Diff Checker")
    }
}
struct DiffCheckerTool: Tool {
    let name = "Diff Checker"
    let icon = "arrow.left.arrow.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Compare text"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 3
    var view: AnyView { AnyView(DiffCheckerView()) }
}
