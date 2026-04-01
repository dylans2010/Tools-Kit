import SwiftUI
struct MetadataRemoverView: View {
    @StateObject private var backend = MetadataRemoverBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Remove Metadata") { backend.clean() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Metadata Remover")
    }
}
struct MetadataRemoverTool: Tool {
    let name = "Metadata Remover"
    let icon = "minus.square.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Remove metadata"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(MetadataRemoverView()) }
}
