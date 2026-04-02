import SwiftUI
struct JWTDecoderView: View {
    @StateObject private var backend = JWTDecoderBackend()
    var body: some View {
        VStack(spacing: 20) {
            TextField("JWT Token", text: $backend.token)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Decode") {
                backend.decode()
            }
            .buttonStyle(.borderedProminent)

            Text(backend.decoded)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
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
