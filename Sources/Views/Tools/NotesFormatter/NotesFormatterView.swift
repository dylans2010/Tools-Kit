import SwiftUI

struct NotesFormatterView: View {
    @StateObject private var backend = NotesFormatterBackend()
    @State private var selectedStyle: NoteFormatStyle = .bulletPoints

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Input Notes").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $backend.inputText)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            HStack {
                Picker("Format Style", selection: $selectedStyle) {
                    ForEach(NoteFormatStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)

                Button("Apply") {
                    backend.format(to: selectedStyle)
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Formatted Output").font(.caption).foregroundColor(.secondary)
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
        }
        .padding()
        .navigationTitle("Notes Formatter")
    }
}

struct NotesFormatterTool: Tool {
    let name = "Notes Formatter"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Format and clean up text notes"
    let requiresAPI = false
    var view: AnyView { AnyView(NotesFormatterView()) }
}
