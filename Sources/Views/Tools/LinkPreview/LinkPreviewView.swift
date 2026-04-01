import SwiftUI
struct LinkPreviewView: View {
    @StateObject private var backend = LinkPreviewBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Preview Link") { backend.fetch() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Link Preview")
    }
}
struct LinkPreviewTool: Tool {
    let name = "Link Preview"
    let icon = "link.circle.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Link Preview"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(LinkPreviewView()) }
}
