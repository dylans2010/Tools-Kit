import SwiftUI
struct WebhookTesterView: View {
    @StateObject private var backend = WebhookTesterBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Send Webhook") { backend.send() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Webhook Tester")
    }
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
