import SwiftUI
struct JWTDecoderView: View {
    @StateObject private var backend = JWTDecoderBackend()
    var body: some View { VStack { TextField("JWT", text: $backend.token); Button("Decode") { backend.decode() }; Text(backend.decoded) }.navigationTitle("JWT Decoder") }
}
struct JWTDecoderTool: Tool {
    let name = "JWT Decoder"
    let icon = "key.fill"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Decode JWT tokens"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(JWTDecoderView()) }
}
