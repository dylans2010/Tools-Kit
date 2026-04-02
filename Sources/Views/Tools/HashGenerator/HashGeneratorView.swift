import SwiftUI
struct HashGeneratorView: View {
    @StateObject private var backend = HashGeneratorBackend()
    var body: some View {
        VStack(spacing: 20) {
            TextField("Input Text", text: $backend.input)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Generate Hash") {
                backend.generate()
            }
            .buttonStyle(.borderedProminent)

            Text(backend.hash)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Hash Generator")
    }
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
