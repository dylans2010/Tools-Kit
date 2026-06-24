import SwiftUI
import UIKit

enum ModelType: String, CaseIterable, Identifiable {
    case local = "Local"
    case app = "App"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .local: return "cpu"
        case .app: return "bolt.fill"
        }
    }
}

struct AIChatSettingsView: View {
    @Binding var settings: AIChatSettings
    var onSignOut: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @ObservedObject private var memoryStore = AIChatMemoryStore.shared
    @ObservedObject private var modelCatalog = AIModelCatalog.shared
    @ObservedObject private var featureCheck = AIFeatureCheck.shared
    @ObservedObject private var skillsManager = AIService.SkillsManager.shared

    @ObservedObject private var musicMode = MusicModeManager.shared
    @ObservedObject private var workoutsMode = WorkoutsModeManager.shared
    @ObservedObject private var workspaceMode = WorkspaceModeManager.shared
    @ObservedObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @ObservedObject private var gamesMode = GamesModeManager.shared

    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""
    @AppStorage("selectedAgentType") private var selectedAgentType = AgentType.jules.rawValue
    @AppStorage("agentEnabled") private var agentEnabled = false
    @AppStorage("agentDebugModeEnabled") private var debugModeEnabled = false

    @State private var showAvailableLocalModels = false
    @State private var isUploadingToCloud = false
    @State private var currentAppMode: AppMode = .dashboard

    var body: some View {
        NavigationStack {
            Form {
                SettingsHeader()

                Section {
                    AIUsageSelectionCard(selectedType: Binding(
                        get: { settings.aiModelSource == .local ? .local : .app },
                        set: { newValue in
                            settings.aiModelSource = (newValue == .local) ? .local : .appModel
                        }
                    ))
                } header: {
                    Text("AI Usage Mode")
                }

                Section {
                    ModelConfigurationSection(
                        settings: $settings,
                        selectedType: settings.aiModelSource == .local ? .local : .app,
                        modelID: $modelID,
                        selectedProviderID: $selectedProviderID,
                        showAvailableLocalModels: $showAvailableLocalModels
                    )
                } header: {
                    Text("Model Configuration")
                }

                Group {
                    Section {
                        NavigationLink(destination: SkillsView()) {
                            Label {
                                HStack {
                                    Text("AI Skills")
                                    Spacer()
                                    Text("\(skillsManager.skills.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "bolt.square.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    } header: {
                        Label("Capabilities", systemImage: "star.fill")
                    }

                    Section {
                        SystemPromptSection(settings: $settings)
                    } header: {
                        Label("System Prompt", systemImage: "terminal.fill")
                    }

                    Section {
                        PersonalitySection(settings: $settings)
                    } header: {
                        Label("AI Personality & Tone", systemImage: "person.fill")
                    }

                    Section {
                        KnowledgeContextSection(settings: $settings)
                    } header: {
                        Label("Knowledge & Context", systemImage: "book.fill")
                    }
                }

                Group {
                    Section {
                        MemorySection(settings: $settings, memoryStore: memoryStore)
                    } header: {
                        Label("Memory", systemImage: "brain.head.profile")
                    }

                    Section {
                        AdvancedParametersSection(settings: $settings)
                    } header: {
                        Label("Advanced Parameters", systemImage: "slider.horizontal.3")
                    }

                    Section {
                        InterfaceSection(settings: $settings)
                    } header: {
                        Label("Interface", systemImage: "paintbrush.fill")
                    }
                }

                Group {
                    Section {
                        agentSettingsSectionContent
                    } header: {
                        Label("Autonomous Agent", systemImage: "robot.fill")
                    }

                    Section {
                        appModeSectionContent
                    } header: {
                        Label("App Experience", systemImage: "square.grid.2x2.fill")
                    }
                }

                Group {
                    Section {
                        AccountSection(
                            isUploadingToCloud: $isUploadingToCloud,
                            onSync: uploadDataToCloud,
                            onSignOut: signOutCurrentUser
                        )
                    } header: {
                        Label("Account", systemImage: "person.crop.circle.fill")
                    }

                    Section {
                        NavigationLink("Feedback & Support") { FeedbackMainView() }
                        AboutSection()
                    } header: {
                        Label("About", systemImage: "info.circle.fill")
                    }
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAvailableLocalModels) {
                AvailableLocalModelsView()
            }
            .task {
                await modelCatalog.loadModels(for: selectedProviderID, force: false)
                featureCheck.refresh()
            }
            .onAppear {
                currentAppMode = resolveCurrentMode()
            }
        }
    }

    private var agentSettingsSectionContent: some View {
        Group {
            Toggle("Agent Active", isOn: $agentEnabled)
            if agentEnabled {
                Picker("Agent Personality", selection: $selectedAgentType) {
                    Text("System").tag(AgentType.system.rawValue)
                    Text("Jules").tag(AgentType.jules.rawValue)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var appModeSectionContent: some View {
        NavigationLink(destination: AppModePickerView(selectedAppMode: selectedAppMode)) {
            HStack {
                Label(currentAppMode.title, systemImage: currentAppMode.icon)
                Spacer()
                Text("Change Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func uploadDataToCloud() {
        isUploadingToCloud = true
        Task {
            try? await UserDataManager.shared.uploadCurrentUserData()
            await MainActor.run { isUploadingToCloud = false }
        }
    }

    private func signOutCurrentUser() {
        Task {
            try? await AccountAuthService.shared.signOut()
            await MainActor.run {
                onSignOut?()
                dismiss()
            }
        }
    }
}

// MARK: - App Mode Helpers

extension AIChatSettingsView {
    enum AppMode: String, CaseIterable, Identifiable {
        case dashboard, music, workouts, workspace, diagnostics, games
        var id: String { rawValue }
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .music: return "Music"
            case .workouts: return "Workouts"
            case .workspace: return "Workspace"
            case .diagnostics: return "Diagnostics"
            case .games: return "Games"
            }
        }
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .music: return "music.note.list"
            case .workouts: return "figure.strengthtraining.traditional"
            case .workspace: return "rectangle.3.group"
            case .diagnostics: return "stethoscope"
            case .games: return "gamecontroller.fill"
            }
        }
        var tint: Color {
            switch self {
            case .dashboard: return .blue
            case .music: return .pink
            case .workouts: return .mint
            case .workspace: return .indigo
            case .diagnostics: return .teal
            case .games: return .purple
            }
        }
        var description: String {
            switch self {
            case .dashboard: return "Standard Tools & Dashboard"
            case .music: return "Music Player Experience"
            case .workouts: return "AI Fitness Tracking"
            case .workspace: return "Production Workspace"
            case .diagnostics: return "iOS Device Diagnostics Suite"
            case .games: return "Play 29+ games, earn XP & coins"
            }
        }
    }

    private func resolveCurrentMode() -> AppMode {
        if musicMode.isMusicModeEnabled { return .music }
        if workoutsMode.isWorkoutsModeEnabled { return .workouts }
        if workspaceMode.isWorkspaceModeEnabled { return .workspace }
        if diagnosticsMode.isDiagnosticsModeEnabled { return .diagnostics }
        if gamesMode.isGamesModeEnabled { return .games }
        return .dashboard
    }

    var selectedAppMode: Binding<AppMode> {
        Binding(
            get: { currentAppMode },
            set: { newMode in
                currentAppMode = newMode
                if musicMode.isMusicModeEnabled != (newMode == .music) {
                    musicMode.isMusicModeEnabled = (newMode == .music)
                }
                if workoutsMode.isWorkoutsModeEnabled != (newMode == .workouts) {
                    workoutsMode.isWorkoutsModeEnabled = (newMode == .workouts)
                }
                if workspaceMode.isWorkspaceModeEnabled != (newMode == .workspace) {
                    workspaceMode.isWorkspaceModeEnabled = (newMode == .workspace)
                }
                if diagnosticsMode.isDiagnosticsModeEnabled != (newMode == .diagnostics) {
                    diagnosticsMode.isDiagnosticsModeEnabled = (newMode == .diagnostics)
                }
                if gamesMode.isGamesModeEnabled != (newMode == .games) {
                    gamesMode.isGamesModeEnabled = (newMode == .games)
                }
            }
        )
    }
}

struct AppModePickerView: View {
    @Binding var selectedAppMode: AIChatSettingsView.AppMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(AIChatSettingsView.AppMode.allCases) { mode in
            Button {
                selectedAppMode = mode
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(mode.tint)
                        .frame(width: 40, height: 40)
                        .background(mode.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mode.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(mode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("App Mode")
    }
}

// MARK: - Modular Components

struct SettingsHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "ai.characters")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom, 8)

            Text("Customize your AI experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .padding(.vertical)
    }
}

struct AIUsageSelectionCard: View {
    @Binding var selectedType: ModelType

    var body: some View {
        Picker("AI Usage Mode", selection: $selectedType) {
            ForEach(ModelType.allCases) { type in
                Label(type.rawValue, systemImage: type.icon).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
    }
}

struct ModelConfigurationSection: View {
    @Binding var settings: AIChatSettings
    let selectedType: ModelType
    @Binding var modelID: String
    @Binding var selectedProviderID: String
    @Binding var showAvailableLocalModels: Bool

    private let registry = AIProviderRegistry.shared
    @ObservedObject private var modelCatalog = AIModelCatalog.shared

    var body: some View {
        if selectedType == .local {
            Button {
                showAvailableLocalModels = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: "cpu.fill")
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(modelID.isEmpty ? "No Local Model Selected" : modelID)
                            .font(.headline)
                        Text("Manage local inference models")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Provider Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(registry.providers.filter { !["local_models", "afm", "lmstudio"].contains($0.id) }, id: \.id) { provider in
                            ProviderChip(
                                provider: provider,
                                isSelected: selectedProviderID == provider.id
                            ) {
                                selectedProviderID = provider.id
                                settings.selectedProviderID = provider.id
                                Task { await modelCatalog.loadModels(for: provider.id, force: true) }
                            }
                        }
                    }
                }

                if let provider = registry.provider(for: selectedProviderID) {
                    APIKeyRowView(
                        providerID: provider.id,
                        providerName: provider.name,
                        placeholder: provider.apiKeyPlaceholder
                    )

                    Divider()

                    let availableModels = modelCatalog.models(for: selectedProviderID)
                    if !availableModels.isEmpty {
                        Picker("Active Model", selection: $modelID) {
                            ForEach(availableModels) { model in
                                Text(model.name).tag(model.id)
                            }
                        }
                        .onChange(of: modelID) { _, newValue in
                            settings.modelID = newValue
                        }
                    } else {
                        HStack {
                            ProgressView().padding(.trailing, 8)
                            Text("Fetching Models...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Sub-Sections

struct SystemPromptSection: View {
    @Binding var settings: AIChatSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Use Preset", isOn: Binding(
                get: { settings.selectedPresetID != nil },
                set: { usePreset in
                    if !usePreset { settings.selectedPresetID = nil }
                    else if settings.selectedPresetID == nil {
                        settings.selectedPresetID = SystemPromptPreset.builtIn.first?.id
                        settings.systemPrompt = SystemPromptPreset.builtIn.first?.prompt ?? ""
                    }
                }
            ))

            if settings.selectedPresetID != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SystemPromptPreset.builtIn) { preset in
                            PresetCard(preset: preset, isSelected: settings.selectedPresetID == preset.id)
                                .onTapGesture {
                                    settings.selectedPresetID = preset.id
                                    settings.systemPrompt = preset.prompt
                                }
                        }
                    }
                }
            } else {
                TextEditor(text: $settings.systemPrompt)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            NavigationLink("Prompt Variable & Library") {
                 PromptToolsView(settings: $settings)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PersonalitySection: View {
    @Binding var settings: AIChatSettings

    var body: some View {
        Group {
            Toggle("Custom Personality", isOn: $settings.useCustomPersonality)
            if settings.useCustomPersonality {
                TextField("AI Name", text: $settings.personalityName)
                TagEditorView(tags: $settings.personalityTraits, placeholder: "Add Trait (e.g. Friendly)")
            }

            Picker("Tone", selection: $settings.responseTone) {
                ForEach(ResponseTone.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }

            NavigationLink("Response Formatting") {
                ResponseFormatterView(settings: $settings)
            }
        }
    }
}

struct KnowledgeContextSection: View {
    @Binding var settings: AIChatSettings

    var body: some View {
        Group {
            NavigationLink("Context Sources (Files, Web)") {
                ContextManagerView(settings: $settings)
            }
            Toggle("Auto-Inject App Context", isOn: $settings.autoInjectContext)
            Toggle("Include History", isOn: $settings.includeConversationHistory)
        }
    }
}

struct MemorySection: View {
    @Binding var settings: AIChatSettings
    @ObservedObject var memoryStore: AIChatMemoryStore

    var body: some View {
        Group {
            Toggle("Enable Long-term Memory", isOn: $settings.memoryEnabled)
            if settings.memoryEnabled {
                VStack(alignment: .leading) {
                    Text("Sensitivity: \(settings.memorySensitivity, specifier: "%.2f")")
                    Slider(value: $settings.memorySensitivity, in: 0.1...1.0)
                }
                NavigationLink("Manage Memories") {
                    MemoryManagerView(memoryStore: memoryStore)
                }
            }
        }
    }
}

struct AdvancedParametersSection: View {
    @Binding var settings: AIChatSettings

    var body: some View {
        Group {
            VStack(alignment: .leading) {
                Text("Temperature: \(settings.temperature, specifier: "%.1f")")
                Slider(value: $settings.temperature, in: 0...2.0, step: 0.1)
            }
            Stepper("Max Tokens: \(settings.maxTokens)", value: $settings.maxTokens, in: 256...16384, step: 256)
        }
    }
}

struct InterfaceSection: View {
    @Binding var settings: AIChatSettings

    var body: some View {
        Group {
            ColorPickerRow(label: "Bubble Color", hexColor: $settings.bubbleColorHex)
            Toggle("Show Timestamps", isOn: $settings.showTimestamps)
            Toggle("Stream Responses", isOn: $settings.streamResponseText)
        }
    }
}

struct AccountSection: View {
    @Binding var isUploadingToCloud: Bool
    var onSync: () -> Void
    var onSignOut: () -> Void

    var body: some View {
        Group {
            Button(action: onSync) {
                HStack {
                    if isUploadingToCloud { ProgressView().padding(.trailing, 8) }
                    Text(isUploadingToCloud ? "Syncing..." : "Sync to Cloud")
                }
            }
            .disabled(isUploadingToCloud)

            Button(role: .destructive, action: onSignOut) {
                Text("Sign Out")
            }
        }
    }
}

struct AboutSection: View {
    var body: some View {
        Group {
            LabeledContent("App Name", value: "Tools Kit")
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build", value: "2026.5")
            LabeledContent("Platform", value: "iOS / iPadOS")
            LabeledContent("Developer", value: "Dylan")
            LabeledContent("Framework", value: "SwiftUI")

            NavigationLink("Licenses") { LicensesView() }
            NavigationLink("Changelog") { ChangelogView() }

            if let privacyURL = URL(string: "https://toolskit.io/privacy") {
                Link("Privacy Policy", destination: privacyURL)
            }
        }
    }
}

// MARK: - Navigation Helpers

struct PromptToolsView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        List {
            Section("Templates") {
                NavigationLink("Template Library") { PromptTemplateLibraryView() }
            }
            Section("Variables") {
                PromptVariablesView(settings: $settings)
            }
        }
        .navigationTitle("Prompt Tools")
    }
}

struct ContextManagerView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        List {
            NavigationLink("File Sources") { FileContextManagerView(settings: $settings) }
            NavigationLink("Web Sources") { WebContextManagerView(settings: $settings) }
            NavigationLink("RAG & Embeddings") { RAGSettingsView(settings: $settings) }
        }
        .navigationTitle("Context Sources")
    }
}

// MARK: - Supporting Views (Restored)

struct ProviderChip: View {
    let provider: any AIProvider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.white : Color.blue)
                Text(provider.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? .blue.opacity(0.85) : .gray.opacity(0.25), lineWidth: 1.2)
            }
            .shadow(color: isSelected ? .blue.opacity(0.25) : .clear, radius: 8, y: 4)
        }
    }
}

struct APIKeyRowView: View {
    let providerID: String
    let providerName: String
    let placeholder: String

    @State private var key: String = ""
    @State private var isSaved: Bool = false
    @State private var isValidating: Bool = false
    @State private var validationResult: Bool? = nil
    @State private var showKey: Bool = false
    @State private var showCopied = false

    private var draftKeyStorage: String { "aichat.provider.draft.\(providerID)" }

    private let keyManager = APIKeyManager.shared
    private let registry = AIProviderRegistry.shared
    @ObservedObject private var modelCatalog = AIModelCatalog.shared

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

                Button(showCopied ? "Copied" : "Copy") {
                    UIPasteboard.general.string = key
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showCopied = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)

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
        .onChange(of: providerID) { _, _ in loadSavedKey() }
        .onChange(of: key) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: draftKeyStorage)
        }
    }

    private func loadSavedKey() {
        if let draft = UserDefaults.standard.string(forKey: draftKeyStorage), !draft.isEmpty {
            key = draft
            isSaved = keyManager.getKey(for: providerID) == draft
        } else if let saved = keyManager.getKey(for: providerID) {
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
        UserDefaults.standard.set(key, forKey: draftKeyStorage)
        isSaved = true
        validationResult = nil
        Task { await modelCatalog.loadModels(for: providerID, force: true) }
    }

    private func deleteKey() {
        keyManager.deleteKey(for: providerID)
        UserDefaults.standard.removeObject(forKey: draftKeyStorage)
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
        .frame(width: 100)
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
            HStack {
                TextField(placeholder, text: $newTag)
                    .onSubmit { addTag() }
                Button("Add", action: addTag)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            FlowLayout(tags, spacing: 8) { tag in
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
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        newTag = ""
    }
}

struct ColorPickerRow: View {
    let label: String
    @Binding var hexColor: String

    var color: Color {
        Color(hex: hexColor)
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { color },
                set: { newColor in
                    hexColor = newColor.toHex() ?? "000000"
                }
            ), supportsOpacity: false)
            .labelsHidden()
        }
    }
}

struct FileContextManagerView: View {
    @Binding var settings: AIChatSettings
    @State private var newSource = ""

    var body: some View {
        Form {
            Section("Active File Sources") {
                if settings.fileSources.isEmpty {
                    Text("No file sources configured").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(settings.fileSources) { source in
                        HStack {
                            Label(source.path, systemImage: "doc.fill")
                            Spacer()
                        }
                    }
                    .onDelete { settings.fileSources.remove(atOffsets: $0) }
                }
            }
            Section("Add Source") {
                HStack {
                    TextField("File path", text: $newSource)
                    Button("Add") {
                        guard !newSource.isEmpty else { return }
                        settings.fileSources.append(FileSource(path: newSource))
                        newSource = ""
                    }
                }
            }
        }
        .navigationTitle("File Context")
    }
}

struct WebContextManagerView: View {
    @Binding var settings: AIChatSettings
    @State private var newURL = ""

    var body: some View {
        Form {
            Section("Web Sources") {
                if settings.webSources.isEmpty {
                    Text("No web sources configured").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(settings.webSources) { source in
                        HStack {
                            Label(source.url, systemImage: "globe")
                            Spacer()
                        }
                    }
                    .onDelete { settings.webSources.remove(atOffsets: $0) }
                }
            }
            Section("Add URL") {
                HStack {
                    TextField("URL", text: $newURL)
                    Button("Add") {
                        guard !newURL.isEmpty else { return }
                        settings.webSources.append(WebSource(url: newURL))
                        newURL = ""
                    }
                }
            }
        }
        .navigationTitle("Web Context")
    }
}

struct RAGSettingsView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Retrieval Settings") {
                Stepper("Top K Results: \(settings.ragTopK)", value: $settings.ragTopK, in: 1...20)
                VStack(alignment: .leading) {
                    Text("Similarity Threshold: \(settings.ragSimilarityThreshold, specifier: "%.2f")")
                    Slider(value: $settings.ragSimilarityThreshold, in: 0.1...1.0)
                }
            }
        }
        .navigationTitle("RAG Settings")
    }
}

struct PromptTemplateLibraryView: View {
    let templates = [
        ("Code Assistant", "Specialized for code review and generation"),
        ("Creative Writer", "Fiction, poetry, and creative content"),
        ("Data Analyst", "Interpret data and provide insights"),
        ("Teacher", "Explain concepts clearly with examples")
    ]

    var body: some View {
        List {
            ForEach(templates, id: \.0) { name, desc in
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.headline)
                    Text(desc).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Templates")
    }
}

struct PromptVariablesView: View {
    @Binding var settings: AIChatSettings
    @State private var newName = ""
    @State private var newValue = ""

    var body: some View {
        Group {
            Section("Custom Variables") {
                ForEach(settings.promptVariables) { variable in
                    HStack {
                        Text(variable.name).bold()
                        Spacer()
                        Text(variable.value).foregroundColor(.secondary)
                    }
                }
                .onDelete { settings.promptVariables.remove(atOffsets: $0) }

                VStack {
                    TextField("Name", text: $newName)
                    TextField("Value", text: $newValue)
                    Button("Add Variable") {
                        guard !newName.isEmpty else { return }
                        settings.promptVariables.append(PromptVariable(name: newName, value: newValue))
                        newName = ""
                        newValue = ""
                    }
                }
            }
        }
    }
}

struct ResponseFormatterView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Formatting") {
                Toggle("Use Markdown", isOn: $settings.useMarkdown)
                Toggle("Include Code Blocks", isOn: $settings.includeCodeBlocks)
            }
        }
        .navigationTitle("Formatting")
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Section("Open Source Libraries") {
                LabeledContent("SwiftUI", value: "Apple")
                LabeledContent("CryptoKit", value: "Apple")
                LabeledContent("Foundation", value: "Apple")
                LabeledContent("Combine", value: "Apple")
            }
        }
        .navigationTitle("Licenses")
    }
}

struct ChangelogView: View {
    var body: some View {
        List {
            Section("v1.0.0 — May 2026") {
                Label("Initial release with full Workspace SDK", systemImage: "sparkles")
                Label("AI Chat with multi-provider support", systemImage: "bubble.left.and.bubble.right")
                Label("Plugin and Connector architecture", systemImage: "puzzlepiece.extension")
                Label("Complete Developer Guide", systemImage: "book")
            }
        }
        .navigationTitle("Changelog")
    }
}
