import SwiftUI

struct Base64View: View {
    @StateObject private var backend = Base64Backend()

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Input").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $backend.inputText)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            HStack {
                Button("Encode") { backend.encode() }
                Button("Decode") { backend.decode() }
                Spacer()
                Button(action: { backend.clear() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.borderedProminent)
            Text("Input: \(backend.inputText.count) chars • Output: \(backend.outputText.count) chars")
                .font(.caption2)
                .foregroundColor(.secondary)

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
        .navigationTitle("Base64 Tool")
    }
}

struct Base64Tool: Tool {
    let name = "Base64 Tool"
    let icon = "lock.open"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Encode and decode Base64 strings"
    let requiresAPI = false
    var view: AnyView { AnyView(Base64View()) }
}
