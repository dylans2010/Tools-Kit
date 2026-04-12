import SwiftUI

struct HMACGeneratorView: View {
    @StateObject private var backend = HMACGeneratorBackend()
    @State private var message: String = ""
    @State private var key: String = ""

    var body: some View {
        ToolDetailView(tool: HMACGeneratorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Key") {
                    TextField("Secret Key", text: $key)
                        .padding()
                }

                ToolInputSection("Message") {
                    TextEditor(text: $message)
                        .frame(height: 100)
                        .padding(8)
                }

                Button("Generate HMAC (SHA-256)") {
                    backend.generate(message: message, key: key)
                }
                .buttonStyle(.borderedProminent)
                .disabled(message.isEmpty || key.isEmpty)

                if !backend.hmac.isEmpty {
                    ToolOutputView("HMAC Result", value: backend.hmac)
                }
            }
        }
    }
}

struct HMACGeneratorTool: Tool {
    let name = "HMAC Generator"
    let icon = "lock.shield"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Generate Hash-based Message Authentication Codes using SHA-256"
    let requiresAPI = false
    var view: AnyView { AnyView(HMACGeneratorView()) }
}
