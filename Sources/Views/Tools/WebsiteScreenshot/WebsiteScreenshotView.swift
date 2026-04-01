import SwiftUI
struct WebsiteScreenshotView: View {
    @StateObject private var backend = WebsiteScreenshotBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Capture Screenshot") { backend.capture() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Website Screenshot")
    }
}
struct WebsiteScreenshotTool: Tool {
    let name = "Website Screenshot"
    let icon = "web.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Screenshot"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 3
    var view: AnyView { AnyView(WebsiteScreenshotView()) }
}
