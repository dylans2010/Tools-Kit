import SwiftUI

struct AIChatSettingsView: View {
    @Binding var settings: AIChatSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryStore = AIChatMemoryStore.shared
    @StateObject private var modelCatalog = AIModelCatalog.shared
    @StateObject private var musicMode = MusicModeManager.shared

    private let registry = AIProviderRegistry.shared

    var selectedProvider: (any AIProvider)? {
        registry.provider(for: settings.selectedProviderID)
    }

    var body: some View {
        NavigationStack {
            Form {
                providerSection
                apiKeySection
                modelSection
                systemPromptSection
                personalitySection
                expertiseSection
                styleSection
                contextSection
                advancedSection
                chatInterfaceSection
                storageSection
                memorySection
                musicModeSection
                toolVisibilitySection
            }
            .task {
                await loadProviderModels(force: false)
            }
            .onChange(of: settings.selectedProviderID) { _ in
                Task { await loadProviderModels(force: false) }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Provider Section

    private var providerSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(registry.providers, id: \.id) { provider in
                        ProviderChip(
                            provider: provider,
                            isSelected: settings.selectedProviderID == provider.id
                        ) {
                            settings.selectedProviderID = provider.id
                            Task { await loadProviderModels(force: true) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("AI Provider")
        } footer: {
            if let provider = selectedProvider, let url = provider.apiKeyURL {
                Link("Get an API key from \(provider.name)", destination: url)
                    .font(.footnote)
            }
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        Section {
            if let provider = selectedProvider {
                APIKeyRowView(
                    providerID: provider.id,
                    providerName: provider.name,
                    placeholder: provider.apiKeyPlaceholder
                )
            }
        } header: {
            Text("API Key")
        }
    }

    // MARK: - Model Section

    private var modelSection: some View {
        Section("Model") {
            let availableModels = modelCatalog.models(for: settings.selectedProviderID)
            if !availableModels.isEmpty {
                Picker("Model", selection: $settings.modelID) {
                    ForEach(availableModels) { model in
                        HStack {
                            Text(model.name)
                            if model.supportsVision {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        .tag(model.id)
                    }
                }
                .pickerStyle(.navigationLink)

                if let model = availableModels.first(where: { $0.id == settings.modelID }) {
                    HStack {
                        if model.supportsVision {
                            Label("Vision supported", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if let ctx = model.contextLength {
                            Spacer()
                            Text("\(ctx / 1000)K context")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else if modelCatalog.loadingProviders.contains(settings.selectedProviderID) {
                HStack {
                    ProgressView()
                    Text("Loading models…")
                        .foregroundColor(.secondary)
                }
            } else {
                TextField("Model ID", text: $settings.modelID)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Fetch Models") {
                    Task { await loadProviderModels(force: true) }
                }
            }
        }
    }

    // MARK: - System Prompt Section

    private var systemPromptSection: some View {
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
    }

    // MARK: - Personality Section

    private var personalitySection: some View {
        Section("AI Personality") {
            Toggle("Use Custom Personality", isOn: $settings.useCustomPersonality)
            if settings.useCustomPersonality {
                TextField("Personality Name", text: $settings.personalityName)
                TagEditorView(tags: $settings.personalityTraits, placeholder: "Add trait...")
            }
        }
    }

    // MARK: - Expertise Section

    private var expertiseSection: some View {
        Section("Expertise Areas") {
            TagEditorView(tags: $settings.expertiseAreas, placeholder: "Add expertise...")
        }
    }

    // MARK: - Style Section

    private var styleSection: some View {
        Section("Personality & Style") {
            Picker("Response Tone", selection: $settings.responseTone) {
                ForEach(ResponseTone.allCases, id: \.self) { tone in
                    Text(tone.rawValue).tag(tone)
                }
            }
            Picker("Response Length", selection: $settings.preferredResponseLength) {
                ForEach(ResponseLength.allCases, id: \.self) { length in
                    Text(length.rawValue).tag(length)
                }
            }
        }
    }

    // MARK: - Context Section

    private var contextSection: some View {
        Section("Knowledge & Context") {
            TextEditor(text: $settings.knowledgeContext)
                .frame(minHeight: 80)
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
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
    }

    // MARK: - Chat Interface Section

    private var chatInterfaceSection: some View {
        Section("Chat Interface") {
            ColorPickerRow(label: "Bubble Color", hexColor: $settings.bubbleColorHex)
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Size: \(Int(settings.fontSize))pt")
                Slider(value: $settings.fontSize, in: 12...22, step: 1)
            }
            Toggle("Show Timestamps", isOn: $settings.showTimestamps)
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        Section("Storage & Reliability") {
            Toggle("Save Chat History", isOn: $settings.saveChatHistory)
            Toggle("Detailed Error Logging", isOn: $settings.logErrorsToConsole)
            Toggle("Enable Streaming (experimental)", isOn: $settings.streamResponseText)
        }
    }

    // MARK: - Memory Section

    private var memorySection: some View {
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

    // MARK: - Music Mode Section

    private var musicModeSection: some View {
        Section {
            Toggle(isOn: $musicMode.isMusicModeEnabled) {
                HStack(spacing: 14) {
                    Image(systemName: "music.note.list")
                        .font(.title3)
                        .foregroundColor(.pink)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Turn ToolsKit Into Music")
                            .font(.body)
                        Text("Replace the Dashboard with the Music player")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if musicMode.isLocked {
                            Text("Locked by bundle identifier containing “Music”.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .disabled(musicMode.isLocked)
        } header: {
            Text("Music Mode")
        } footer: {
            Text("When enabled, ToolsKit launches directly into the Music library instead of the Dashboard.")
                .font(.caption)
        }
    }

    // MARK: - Tool Visibility Section

    private var toolVisibilitySection: some View {
        Section {
            NavigationLink {
                ToolVisibilitySettingsView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tool Visibility")
                            .font(.body)
                        Text("Show or hide tools on the Dashboard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Dashboard")
        }
    }

    private func loadProviderModels(force: Bool) async {
        let providerID = settings.selectedProviderID
        await modelCatalog.loadModels(for: providerID, force: force)
        let models = await MainActor.run { modelCatalog.models(for: providerID) }
        await MainActor.run {
            if !models.contains(where: { $0.id == settings.modelID }) {
                settings.modelID = models.first?.id ?? ""
            }
        }
    }
}

// MARK: - Provider Chip

struct ProviderChip: View {
    let provider: any AIProvider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                Text(provider.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 64)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - API Key Row

struct APIKeyRowView: View {
    let providerID: String
    let providerName: String
    let placeholder: String

    @State private var key: String = ""
    @State private var isSaved: Bool = false
    @State private var isValidating: Bool = false
    @State private var validationResult: Bool? = nil
    @State private var showKey: Bool = false

    private let keyManager = APIKeyManager.shared
    private let registry = AIProviderRegistry.shared
    @StateObject private var modelCatalog = AIModelCatalog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Group {
                    if showKey {
                        TextField(placeholder, text: $key)
                    } else {
                        SecureField(placeholder, text: $key)
                    }
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.none)

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button(isSaved ? "Update Key" : "Save Key") {
                    saveKey()
                }
                .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if isSaved {
                    Button("Delete") { deleteKey() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)

                    Button("Validate") { validateKey() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isValidating)
                }

                if isValidating {
                    ProgressView().scaleEffect(0.7)
                } else if let result = validationResult {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result ? .green : .red)
                    Text(result ? "Valid" : "Invalid")
                        .font(.caption)
                        .foregroundColor(result ? .green : .red)
                }
            }
        }
        .onAppear { loadSavedKey() }
        .onChange(of: providerID) { _ in loadSavedKey() }
    }

    private func loadSavedKey() {
        if let saved = keyManager.getKey(for: providerID) {
            key = saved
            isSaved = true
        } else {
            key = ""
            isSaved = false
            validationResult = nil
        }
    }

    private func saveKey() {
        guard keyManager.saveKey(key, for: providerID) else { return }
        isSaved = true
        validationResult = nil
        Task { await modelCatalog.loadModels(for: providerID, force: true) }
    }

    private func deleteKey() {
        keyManager.deleteKey(for: providerID)
        key = ""
        isSaved = false
        validationResult = nil
        Task { await modelCatalog.loadModels(for: providerID, force: true) }
    }

    private func validateKey() {
        guard let provider = registry.provider(for: providerID) else { return }
        isValidating = true
        validationResult = nil
        Task {
            do {
                let result = try await provider.validateAPIKey(key)
                await MainActor.run {
                    validationResult = result
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationResult = false
                    isValidating = false
                }
            }
        }
    }
}

// MARK: - Supporting Views (unchanged)

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
