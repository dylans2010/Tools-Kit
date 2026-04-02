import SwiftUI
struct PromptGeneratorView: View {
    @StateObject private var backend = PromptGeneratorBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Generate") {
                backend.generate()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
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
