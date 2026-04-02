import SwiftUI
struct CodeExplainerView: View {
    @StateObject private var backend = CodeExplainerBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Explain") {
                backend.explain()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Code Explainer")
    }
}
struct CodeExplainerTool: Tool {
    let name = "Code Explainer"
    let icon = "curlybraces.square.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Explain"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 4
    var view: AnyView { AnyView(CodeExplainerView()) }
}
