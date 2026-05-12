import SwiftUI

struct XMLFormatterView: View {
    @StateObject private var backend = XMLFormatterBackend()

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Input XML").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $backend.inputText)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            Button(action: { backend.format() }) {
                Text("Format XML")
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
                    .disabled(backend.outputText.isEmpty)
                }
                TextEditor(text: .constant(backend.outputText))
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.2)))
            }
        }
        .padding()
        .navigationTitle("XML Formatter")
    }
}

struct XMLFormatterTool: Tool, Sendable {
    let name = "XML Formatter"
    let icon = "chevron.left.slash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Format XML"
    let requiresAPI = false
    var view: AnyView { AnyView(XMLFormatterView()) }
}
