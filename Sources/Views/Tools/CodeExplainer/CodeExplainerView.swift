import SwiftUI
struct CodeExplainerView: View {
    @StateObject private var backend = CodeExplainerBackend()
    var body: some View { Button("Explain") { backend.explain() }.navigationTitle("Explainer") }
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
