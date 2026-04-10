import SwiftUI

struct AIChatSettingsView: View {
    @Binding var settings: AIChatSettings
    @Environment(\.dismiss) private var dismiss
    @State private var newTrait: String = ""
    @State private var newExpertise: String = ""
    @StateObject private var memoryStore = AIChatMemoryStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    TextField("e.g. google/gemini-2.0-flash-exp:free", text: $settings.modelID)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Link("Browse models at openrouter.ai", destination: URL(string: "https://openrouter.ai/models")!)
                        .font(.footnote)
                }

                Section("System Prompt") {
                    Toggle("Use Preset", isOn: Binding(
                        get: { settings.selectedPresetID != nil },
                        set: { usePreset in
                            if !usePreset { settings.selectedPresetID = nil }
                            else if settings.selectedPresetID == nil {
                                settings.selectedPresetID = SystemPromptPreset.builtIn.first?.id
                            }
                        }
                    ))

                    if settings.selectedPresetID != nil {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                            ForEach(SystemPromptPreset.builtIn) { preset in
                                PresetCard(preset: preset, isSelected: settings.selectedPresetID == preset.id)
                                    .onTapGesture {
                                        settings.selectedPresetID = preset.id
                                        settings.systemPrompt = preset.prompt
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        TextEditor(text: $settings.systemPrompt)
                            .frame(minHeight: 80)
                    }
                }

                Section("AI Personality") {
                    Toggle("Use Custom Personality", isOn: $settings.useCustomPersonality)
                    if settings.useCustomPersonality {
                        TextField("Personality Name", text: $settings.personalityName)
                        TagEditorView(tags: $settings.personalityTraits, placeholder: "Add trait...")
                    }
                }

                Section("Expertise Areas") {
                    TagEditorView(tags: $settings.expertiseAreas, placeholder: "Add expertise...")
                }

                Section("Knowledge & Context") {
                    TextEditor(text: $settings.knowledgeContext)
                        .frame(minHeight: 80)
                }

                Section("Advanced") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temperature: \(settings.temperature, specifier: "%.1f")")
                        Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                    }
                    Stepper("Max Tokens: \(settings.maxTokens)", value: $settings.maxTokens, in: 256...8192, step: 256)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top P: \(settings.topP, specifier: "%.2f")")
                        Slider(value: $settings.topP, in: 0...1, step: 0.05)
                    }
                }

                Section("Chat Interface") {
                    ColorPickerRow(label: "Bubble Color", hexColor: $settings.bubbleColorHex)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font Size: \(Int(settings.fontSize))pt")
                        Slider(value: $settings.fontSize, in: 12...22, step: 1)
                    }
                    Toggle("Show Timestamps", isOn: $settings.showTimestamps)
                }

                Section("Storage & Reliability") {
                    Toggle("Save Chat History", isOn: $settings.saveChatHistory)
                    Toggle("Detailed Error Logging", isOn: $settings.logErrorsToConsole)
                    Toggle("Enable Streaming (experimental)", isOn: $settings.streamResponseText)
                }

                Section("Memory (CoreML-assisted)") {
                    Toggle("Enable Memory", isOn: $settings.memoryEnabled)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sensitivity: \(settings.memorySensitivity, specifier: "%.2f")")
                        Slider(value: $settings.memorySensitivity, in: 0.2...1.0, step: 0.05)
                    }
                    NavigationLink("Manage Saved Memory") {
                        MemoryManagerView(memoryStore: memoryStore)
                    }
                }
            }
            .navigationTitle("AI Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MemoryManagerView: View {
    @ObservedObject var memoryStore: AIChatMemoryStore

    var body: some View {
        List {
            if memoryStore.memories.isEmpty {
                Text("No memory items have been captured yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(memoryStore.memories) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.value)
                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        memoryStore.delete(memoryStore.memories[index])
                    }
                }
            }
        }
        .navigationTitle("AI Memory")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") { memoryStore.clear() }
                    .foregroundColor(.red)
            }
        }
    }
}

struct PresetCard: View {
    let preset: SystemPromptPreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: preset.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
            Text(preset.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct TagEditorView: View {
    @Binding var tags: [String]
    let placeholder: String
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(tags: tags) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.caption)
                    Button {
                        tags.removeAll { $0 == tag }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
            }

            HStack {
                TextField(placeholder, text: $newTag)
                    .onSubmit { addTag() }
                Button("Add", action: addTag)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        newTag = ""
    }
}

struct FlowLayout<Content: View>: View {
    let tags: [String]
    let content: (String) -> Content

    init(tags: [String], @ViewBuilder content: @escaping (String) -> Content) {
        self.tags = tags
        self.content = content
    }

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    content(tag)
                }
            }
        }
    }
}

struct ColorPickerRow: View {
    let label: String
    @Binding var hexColor: String

    var color: Color {
        Color(hex: hexColor) ?? .blue
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { color },
                set: { newColor in
                    if let hex = newColor.toHex() {
                        hexColor = hex
                    }
                }
            ), supportsOpacity: false)
            .labelsHidden()
        }
    }
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else { return nil }
        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uic.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
