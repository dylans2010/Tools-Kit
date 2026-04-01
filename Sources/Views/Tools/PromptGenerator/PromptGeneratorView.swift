import SwiftUI
struct PromptGeneratorView: View {
    @StateObject private var backend = PromptGeneratorBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Generate Prompt") { backend.generate() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Prompt Generator")
    }
}
struct PromptGeneratorTool: Tool {
    let name = "Prompt Generator"
    let icon = "bolt.badge.a"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Generate prompt"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 2
    var view: AnyView { AnyView(PromptGeneratorView()) }
}
