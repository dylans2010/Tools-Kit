import SwiftUI
struct EmailGeneratorView: View {
    @StateObject private var backend = EmailGeneratorBackend()
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
        .navigationTitle("Email Assistant")
    }
}
struct EmailGeneratorTool: Tool {
    let name = "Email Assistant"
    let icon = "envelope.open.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Email assistant"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 2
    var view: AnyView { AnyView(EmailGeneratorView()) }
}
