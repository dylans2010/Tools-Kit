import SwiftUI

struct IntegrationEditorView: View {
    let tool: IntegrationTool?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared

    @State private var name: String
    @State private var description: String
    @State private var promptTemplate: String
    @State private var systemPrompt: String
    @State private var temperature: Double
    @State private var aiModel: String
    @State private var isEnabled: Bool

    init(tool: IntegrationTool?) {
        self.tool = tool
        _name = State(initialValue: tool?.name ?? "")
        _description = State(initialValue: tool?.description ?? "")
        _promptTemplate = State(initialValue: tool?.promptTemplate ?? "")
        _systemPrompt = State(initialValue: tool?.systemPrompt ?? "You are a helpful assistant.")
        _temperature = State(initialValue: tool?.temperature ?? 0.7)
        _aiModel = State(initialValue: tool?.aiModel ?? "openai/gpt-3.5-turbo")
        _isEnabled = State(initialValue: tool?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("General Info") {
                    TextField("Name (e.g. Tone Adjuster)", text: $name)
                    TextField("Description", text: $description)
                }

                Section("AI Configuration") {
                    TextField("AI Model", text: $aiModel)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", temperature))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                    }
                }

                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 80)
                        .font(.system(.body, design: .monospaced))
                }

                Section {
                    TextEditor(text: $promptTemplate)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("User Prompt Template")
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
                        updated.systemPrompt = systemPrompt
                        updated.temperature = temperature
                        updated.aiModel = aiModel
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
