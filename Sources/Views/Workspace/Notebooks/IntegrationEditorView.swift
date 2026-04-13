import SwiftUI

struct IntegrationEditorView: View {
    let tool: IntegrationTool?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared

    @State private var name: String
    @State private var description: String
    @State private var promptTemplate: String
    @State private var isEnabled: Bool

    init(tool: IntegrationTool?) {
        self.tool = tool
        _name = State(initialValue: tool?.name ?? "")
        _description = State(initialValue: tool?.description ?? "")
        _promptTemplate = State(initialValue: tool?.promptTemplate ?? "")
        _isEnabled = State(initialValue: tool?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Tone Adjuster", text: $name)
                }

                Section("Description") {
                    TextField("What does this integration do?", text: $description)
                }

                Section {
                    TextEditor(text: $promptTemplate)
                        .frame(minHeight: 140)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Prompt Template")
                } footer: {
                    Text("Use {{content}} to insert the page content into your prompt.")
                        .font(.caption)
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .navigationTitle(tool == nil ? "New Integration" : "Edit Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updated = tool ?? IntegrationTool()
                        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : name
                        updated.description = description
                        updated.promptTemplate = promptTemplate
                        updated.isEnabled = isEnabled
                        manager.saveIntegration(updated)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.large])
    }
}
