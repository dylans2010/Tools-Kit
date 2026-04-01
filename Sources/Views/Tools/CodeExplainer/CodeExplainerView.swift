import SwiftUI
struct CodeExplainerView: View {
    @StateObject private var backend = CodeExplainerBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Explain Code") { backend.explain() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
