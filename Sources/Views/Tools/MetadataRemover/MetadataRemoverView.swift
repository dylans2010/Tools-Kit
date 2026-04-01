import SwiftUI
struct MetadataRemoverView: View {
    @StateObject private var backend = MetadataRemoverBackend()
    var body: some View { Button("Clean") { backend.clean() }.navigationTitle("Metadata") }
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
