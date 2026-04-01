import SwiftUI
struct TextRewriterView: View {
    @StateObject private var backend = TextRewriterBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Rewrite Text") { backend.rewrite() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Text Rewriter")
    }
}
struct TextRewriterTool: Tool {
    let name = "Text Rewriter"
    let icon = "pencil.tip.crop.circle.badge.plus"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Rewrite"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 3
    var view: AnyView { AnyView(TextRewriterView()) }
}
