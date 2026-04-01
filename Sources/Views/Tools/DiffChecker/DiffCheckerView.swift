import SwiftUI
struct DiffCheckerView: View {
    @StateObject private var backend = DiffCheckerBackend()
    var body: some View { Button("Check Diff") { backend.check() }.navigationTitle("Diff Checker") }
}
struct DiffCheckerTool: Tool {
    let name = "Diff Checker"
    let icon = "arrow.left.arrow.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Compare text"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 3
    var view: AnyView { AnyView(DiffCheckerView()) }
}
