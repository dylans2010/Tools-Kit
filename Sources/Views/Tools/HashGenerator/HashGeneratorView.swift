import SwiftUI
struct HashGeneratorView: View {
    @StateObject private var backend = HashGeneratorBackend()
    var body: some View { VStack { TextField("Input", text: $backend.input); Button("Hash") { backend.generate() }; Text(backend.hash) }.navigationTitle("Hash Generator") }
}
struct HashGeneratorTool: Tool {
    let name = "Hash Generator"
    let icon = "number.square"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Generate hashes"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(HashGeneratorView()) }
}
