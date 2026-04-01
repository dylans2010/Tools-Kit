import SwiftUI
struct HashGeneratorView: View {
    @StateObject private var backend = HashGeneratorBackend()
    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextField("Enter text to hash", text: $backend.input)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            Section {
                Button("Generate Hash") { backend.generate() }
                    .buttonStyle(.borderedProminent)
            }
            Section(header: Text("Hash Result")) {
                Text(backend.hash.isEmpty ? "No hash generated yet" : backend.hash)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(backend.hash.isEmpty ? .secondary : .primary)
            }
        }
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
