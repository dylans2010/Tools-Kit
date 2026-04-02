import SwiftUI
struct IdeaGeneratorView: View {
    @StateObject private var backend = IdeaGeneratorBackend()
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
        .navigationTitle("Idea Generator")
    }
}
struct IdeaGeneratorTool: Tool {
    let name = "Idea Generator"
    let icon = "lightbulb.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Idea gen"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 2
    var view: AnyView { AnyView(IdeaGeneratorView()) }
}
