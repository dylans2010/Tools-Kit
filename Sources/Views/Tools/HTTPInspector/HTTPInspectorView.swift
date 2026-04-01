import SwiftUI
struct HTTPInspectorView: View {
    @StateObject private var backend = HTTPInspectorBackend()
    var body: some View { Button("Inspect") { backend.inspect() }.navigationTitle("HTTP Inspector") }
}
struct HTTPInspectorTool: Tool {
    let name = "HTTP Inspector"
    let icon = "network.badge.shield.half.filled"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "HTTP Inspector"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 4
    var view: AnyView { AnyView(HTTPInspectorView()) }
}
