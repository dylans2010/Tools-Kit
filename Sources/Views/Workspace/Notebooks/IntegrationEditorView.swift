import SwiftUI

struct IntegrationEditorView: View {
    let tool: IntegrationTool?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared

    @State private var name: String
    @State private var description: String
    @State private var category: String
    @State private var tagsCSV: String
    @State private var promptTemplate: String
    @State private var systemPrompt: String
    @State private var temperature: Double
    @State private var topP: Double
    @State private var frequencyPenalty: Double
    @State private var presencePenalty: Double
    @State private var maxResponseTokens: Int
    @State private var aiModel: String
    @State private var triggerMode: IntegrationTool.TriggerMode
    @State private var inputScope: IntegrationTool.InputScope
    @State private var outputStyle: IntegrationTool.OutputStyle
    @State private var includeAttachmentsContext: Bool
    @State private var runInBackground: Bool
    @State private var allowWebResults: Bool
    @State private var timeoutSeconds: Int
    @State private var requiredVariablesText: String
    @State private var exampleInputsText: String
    @State private var postProcessingText: String
    @State private var aiBuildPrompt: String
    @State private var isBuildingAI = false
    @State private var isEnabled: Bool

    init(tool: IntegrationTool?) {
        self.tool = tool
        _name = State(initialValue: tool?.name ?? "")
        _description = State(initialValue: tool?.description ?? "")
        _category = State(initialValue: tool?.category ?? "General")
        _tagsCSV = State(initialValue: (tool?.tags ?? []).joined(separator: ", "))
        _promptTemplate = State(initialValue: tool?.promptTemplate ?? "{{content}}")
        _systemPrompt = State(initialValue: tool?.systemPrompt ?? "You are a helpful assistant.")
        _temperature = State(initialValue: tool?.temperature ?? 0.7)
        _topP = State(initialValue: tool?.topP ?? 1.0)
        _frequencyPenalty = State(initialValue: tool?.frequencyPenalty ?? 0.0)
        _presencePenalty = State(initialValue: tool?.presencePenalty ?? 0.0)
        _maxResponseTokens = State(initialValue: tool?.maxResponseTokens ?? 1200)
        _aiModel = State(initialValue: tool?.aiModel ?? "openai/gpt-3.5-turbo")
        _triggerMode = State(initialValue: tool?.triggerMode ?? .manual)
        _inputScope = State(initialValue: tool?.inputScope ?? .currentPage)
        _outputStyle = State(initialValue: tool?.outputStyle ?? .markdown)
        _includeAttachmentsContext = State(initialValue: tool?.includeAttachmentsContext ?? true)
        _runInBackground = State(initialValue: tool?.runInBackground ?? false)
        _allowWebResults = State(initialValue: tool?.allowWebResults ?? false)
        _timeoutSeconds = State(initialValue: tool?.timeoutSeconds ?? 60)
        _requiredVariablesText = State(initialValue: (tool?.requiredVariables ?? []).joined(separator: "\n"))
        _exampleInputsText = State(initialValue: (tool?.exampleInputs ?? []).joined(separator: "\n"))
        _postProcessingText = State(initialValue: (tool?.postProcessingRules ?? []).joined(separator: "\n"))
        _aiBuildPrompt = State(initialValue: tool?.aiBuildPrompt ?? "")
        _isEnabled = State(initialValue: tool?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Builder") {
                    TextEditor(text: $aiBuildPrompt)
                        .frame(minHeight: 80)
                        .font(.body)
                        .overlay(
                            Group {
                                if aiBuildPrompt.isEmpty {
                                    Text("Describe the tool you want AI to build for you...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )

                    Button {
                        buildWithAI()
                    } label: {
                        HStack {
                            if isBuildingAI {
                                ProgressView().padding(.trailing, 8)
                            }
                            Label("Build", systemImage: "sparkles")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBuildingAI || aiBuildPrompt.isEmpty)
                }

                Section {
                    TextField("Name (e.g. Meeting Action Extractor)", text: $name)
                    TextField("Category (e.g. Product, Study, Meetings)", text: $category)
                    TextField("Tags (comma-separated)", text: $tagsCSV)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Tool Identity")
                }

                Section {
                    Picker("Trigger", selection: $triggerMode) {
                        ForEach(IntegrationTool.TriggerMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Picker("Input Scope", selection: $inputScope) {
                        ForEach(IntegrationTool.InputScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    Picker("Output Style", selection: $outputStyle) {
                        ForEach(IntegrationTool.OutputStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                } header: {
                    Text("Execution Mode")
                }

                Section {
                    TextField("AI Model", text: $aiModel)
                        .autocapitalization(.none)
                        .keyboardType(.asciiCapable)
                        .disableAutocorrection(true)

                    sliderRow("Temperature", value: $temperature, range: 0...1, step: 0.05)
                    sliderRow("Top-P", value: $topP, range: 0...1, step: 0.05)
                    sliderRow("Frequency Penalty", value: $frequencyPenalty, range: -2...2, step: 0.1)
                    sliderRow("Presence Penalty", value: $presencePenalty, range: -2...2, step: 0.1)

                    Stepper("Max Tokens: \(maxResponseTokens)", value: $maxResponseTokens, in: 64...8192, step: 64)
                    Stepper("Timeout: \(timeoutSeconds)s", value: $timeoutSeconds, in: 10...300, step: 5)
                } header: {
                    Text("AI Configuration")
                }

                Section {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 90)
                        .font(.system(.body, design: .monospaced))

                    TextEditor(text: $promptTemplate)
                        .frame(minHeight: 130)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Prompt Design")
                } footer: {
                    Text("Supported placeholders: {{content}} page body, {{title}} page title, {{attachments}} file names, {{word_count}} note size, {{timestamp}} current date/time.")
                        .font(.caption)
                }

                Section {
                    TextEditor(text: $requiredVariablesText)
                        .frame(minHeight: 70)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Advanced Inputs")
                } footer: {
                    Text("One required variable per line (e.g. tone, audience, objective).")
                        .font(.caption)
                }

                Section {
                    TextEditor(text: $exampleInputsText)
                        .frame(minHeight: 90)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Examples")
                } footer: {
                    Text("Provide sample user inputs, one per line, to guide reproducible behavior.")
                        .font(.caption)
                }

                Section {
                    TextEditor(text: $postProcessingText)
                        .frame(minHeight: 90)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Post-processing Rules")
                } footer: {
                    Text("Optional rules to enforce final formatting/cleanup after AI output.")
                        .font(.caption)
                }

                Section {
                    Toggle("Include Attachments Context", isOn: $includeAttachmentsContext)
                    Toggle("Allow Web Results (if provider supports it)", isOn: $allowWebResults)
                    Toggle("Run in Background Mode", isOn: $runInBackground)
                    Toggle("Enabled", isOn: $isEnabled)
                } header: {
                    Text("Runtime Options")
                }
            }
            .navigationTitle(tool == nil ? "New Integration" : "Edit Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: save)
                        .bold()
                }
            }
        }
        .presentationDetents([.large])
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func splitLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func splitCSV(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func buildWithAI() {
        isBuildingAI = true
        Task {
            do {
                let schema = """
                {
                  "type": "object",
                  "properties": {
                    "name": { "type": "string" },
                    "description": { "type": "string" },
                    "category": { "type": "string" },
                    "systemPrompt": { "type": "string" },
                    "promptTemplate": { "type": "string" },
                    "aiModel": { "type": "string" }
                  }
                }
                """
                let result = try await AIService.shared.generateStructuredJSON(
                    prompt: "Build an integration tool based on this description: \(aiBuildPrompt)",
                    jsonSchema: schema
                )

                if let data = result.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        name = json["name"] as? String ?? name
                        description = json["description"] as? String ?? description
                        category = json["category"] as? String ?? category
                        systemPrompt = json["systemPrompt"] as? String ?? systemPrompt
                        promptTemplate = json["promptTemplate"] as? String ?? promptTemplate
                        aiModel = json["aiModel"] as? String ?? aiModel
                    }
                }
            } catch {
                print("AI Build failed: \(error)")
            }
            await MainActor.run { isBuildingAI = false }
        }
    }

    private func save() {
        var updated = tool ?? IntegrationTool()
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : name
        updated.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.category = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : category
        updated.tags = splitCSV(tagsCSV)
        updated.promptTemplate = promptTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.systemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.temperature = temperature
        updated.topP = topP
        updated.frequencyPenalty = frequencyPenalty
        updated.presencePenalty = presencePenalty
        updated.maxResponseTokens = maxResponseTokens
        let trimmedModel = aiModel.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.aiModel = trimmedModel.isEmpty ? "openai/gpt-3.5-turbo" : trimmedModel
        updated.triggerMode = triggerMode
        updated.inputScope = inputScope
        updated.outputStyle = outputStyle
        updated.includeAttachmentsContext = includeAttachmentsContext
        updated.runInBackground = runInBackground
        updated.allowWebResults = allowWebResults
        updated.timeoutSeconds = timeoutSeconds
        updated.requiredVariables = splitLines(requiredVariablesText)
        updated.exampleInputs = splitLines(exampleInputsText)
        updated.postProcessingRules = splitLines(postProcessingText)
        updated.aiBuildPrompt = aiBuildPrompt
        updated.isEnabled = isEnabled
        manager.saveIntegration(updated)
        dismiss()
    }
}
