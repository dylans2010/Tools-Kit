import SwiftUI
struct WebhookTesterView: View {
    @StateObject private var backend = WebhookTesterBackend()
    var body: some View { Button("Send Webhook") { backend.send() }.navigationTitle("Webhook Tester") }
}
struct WebhookTesterTool: Tool {
    let name = "Webhook Tester"
    let icon = "link.badge.plus"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Test webhooks"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 4
    var view: AnyView { AnyView(WebhookTesterView()) }
}
