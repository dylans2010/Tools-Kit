import SwiftUI
struct WebsiteScreenshotView: View {
    @StateObject private var backend = WebsiteScreenshotBackend()
    var body: some View { Button("Capture") { backend.capture() }.navigationTitle("Screenshot") }
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
