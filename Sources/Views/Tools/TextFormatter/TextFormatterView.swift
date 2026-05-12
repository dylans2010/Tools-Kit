import SwiftUI

struct TextFormatterView: View {
    @StateObject private var backend = TextFormatterBackend()
    @State private var selectedStyle: TextCaseStyle = .uppercase

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Input Text").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $backend.inputText)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            HStack {
                Picker("Style", selection: $selectedStyle) {
                    ForEach(TextCaseStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)

                Button("Format") {
                    backend.format(to: selectedStyle)
                }
                .buttonStyle(.borderedProminent)
                Button("Clear") {
                    backend.inputText = ""
                    backend.outputText = ""
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Output").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button(action: { UIPasteboard.general.string = backend.outputText }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(backend.outputText.isEmpty)
                }
                TextEditor(text: .constant(backend.outputText))
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.2)))
            }
            HStack {
                Text("Input Chars: \(backend.inputText.count)")
                Spacer()
                Text("Output Chars: \(backend.outputText.count)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Text Formatter")
    }
}

struct TextFormatterTool: Tool, Sendable {
    let name = "Text Formatter"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Convert text between various cases"
    let requiresAPI = false
    var view: AnyView { AnyView(TextFormatterView()) }
}
