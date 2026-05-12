import SwiftUI

struct JSONFormatterView: View {
    @StateObject private var backend = JSONFormatterBackend()

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Input JSON").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $backend.inputText)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(backend.isValid ? Color.gray.opacity(0.2) : Color.red.opacity(0.5)))
            }

            Button(action: { backend.format() }) {
                Text("Format and Validate")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            VStack(alignment: .leading) {
                HStack {
                    Text("Output").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button(action: { UIPasteboard.general.string = backend.outputText }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .disabled(backend.outputText.isEmpty || !backend.isValid)
                }
                TextEditor(text: .constant(backend.outputText))
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.2)))
            }
        }
        .padding()
        .navigationTitle("JSON Formatter")
    }
}

struct JSONFormatterTool: Tool, Sendable {
    let name = "JSON Formatter"
    let icon = "chevron.left.forwardslash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Format and validate JSON data"
    let requiresAPI = false
    var view: AnyView { AnyView(JSONFormatterView()) }
}
