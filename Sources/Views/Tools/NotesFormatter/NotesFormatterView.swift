import SwiftUI

struct NotesFormatterView: View {
    @StateObject private var backend = NotesFormatterBackend()
    @State private var selectedStyle: NoteFormatStyle = .bulletPoints

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your raw, unorganized notes here to be cleaned and formatted.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $backend.inputText)
                        .frame(minHeight: 120)
                        .cornerRadius(8)
                }
            } header: {
                Text("Source Notes")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a formatting style and apply it to your notes.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("Style", selection: $selectedStyle) {
                            ForEach(NoteFormatStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()

                        Button(action: { backend.format(to: selectedStyle) }) {
                            Label("Apply Format", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("Formatting Options")
            }

            if !backend.outputText.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: .constant(backend.outputText))
                            .frame(minHeight: 200)
                            .font(.body)

                        HStack {
                            Button(action: { UIPasteboard.general.string = backend.outputText }) {
                                Label("Copy Formatted", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: { backend.outputText = "" }) {
                                Label("Clear", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Formatted Output")
                } footer: {
                    Text("Your notes have been formatted into a clean structure.")
                }
            }
        }
        .navigationTitle("Notes Formatter")
    }
}

struct NotesFormatterTool: Tool, Sendable {
    let name = "Notes Formatter"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Format and clean up text notes"
    let requiresAPI = false
    var view: AnyView { AnyView(NotesFormatterView()) }
}
