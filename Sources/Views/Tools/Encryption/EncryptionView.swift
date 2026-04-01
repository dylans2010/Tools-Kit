import SwiftUI
struct EncryptionView: View {
    @StateObject private var backend = EncryptionBackend()
    var body: some View { Button("Encrypt") { backend.encrypt() }.navigationTitle("Encryption") }
}
struct EncryptionTool: Tool {
    let name = "Text Encryption"
    let icon = "lock.doc"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Encrypt text"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 4
    var view: AnyView { AnyView(EncryptionView()) }
}
