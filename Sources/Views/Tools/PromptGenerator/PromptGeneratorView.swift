import SwiftUI

struct PromptGeneratorView: View {
    @StateObject private var backend = PromptGeneratorBackend()

    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                TextField("Topic / Subject", text: $backend.topic)

                Picker("Target Model", selection: $backend.selectedModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.rawValue).tag(model)
                    }
                }

                Picker("Prompt Category", selection: $backend.selectedType) {
                    ForEach(PromptType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                Toggle("Include Constraints", isOn: $backend.includeConstraints)
            }

            Section {
                Button(action: backend.generate) {
                    Text("Generate Optimized Prompt")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if !backend.generatedPrompt.isEmpty {
                Section(header: Text("Generated Prompt")) {
                    TextEditor(text: .constant(backend.generatedPrompt))
                        .frame(height: 150)
                        .font(.subheadline)

                    Button(action: { UIPasteboard.general.string = backend.generatedPrompt }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .navigationTitle("Prompt Generator")
    }
}

struct PromptGeneratorTool: Tool {
    let name = "Prompt Generator"
    let icon = "bolt.badge.a"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Generate optimized prompts for various AI models"
    let requiresAPI = false
    var view: AnyView { AnyView(PromptGeneratorView()) }
}
