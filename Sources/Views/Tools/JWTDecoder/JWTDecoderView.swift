import SwiftUI
struct JWTDecoderView: View {
    @StateObject private var backend = JWTDecoderBackend()
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Paste JWT token here", text: $backend.token)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Decode") { backend.decode() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                if !backend.decoded.isEmpty {
                    Text(backend.decoded)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("JWT Decoder")
    }
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
