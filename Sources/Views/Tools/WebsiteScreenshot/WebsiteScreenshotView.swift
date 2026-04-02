import SwiftUI
struct WebsiteScreenshotView: View {
    @StateObject private var backend = WebsiteScreenshotBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Capture") {
                backend.capture()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
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
