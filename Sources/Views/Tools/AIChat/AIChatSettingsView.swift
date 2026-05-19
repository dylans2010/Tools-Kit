import SwiftUI
import UIKit

struct AIChatSettingsView: View {
    @Binding var settings: AIChatSettings
    var onSignOut: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryStore = AIChatMemoryStore.shared
    @StateObject private var modelCatalog = AIModelCatalog.shared
    @StateObject private var featureCheck = AIFeatureCheck.shared
    @StateObject private var musicMode = MusicModeManager.shared
    @StateObject private var workoutsMode = WorkoutsModeManager.shared
    @StateObject private var workspaceMode = WorkspaceModeManager.shared
    @StateObject private var skillsManager = AIService.SkillsManager.shared

    @State private var isUploadingToCloud = false
    @State private var cloudStatusMessage: String?
    @State private var isSigningOut = false
    @State private var signOutStatusMessage: String?
    @State private var showFreeOpenRouterSheet = false
    @State private var showFileImporter = false
    @State private var importedFileNames: [String] = []
    @State private var showModelConfigSheet = false
    @State private var unsplashAccessKey = APIKeyManager.shared.unsplashAccessKey ?? ""
    @State private var unsplashSecretKey = APIKeyManager.shared.unsplashSecretKey ?? ""
    @State private var unsplashAppID = APIKeyManager.shared.unsplashApplicationID ?? ""
    @StateObject private var modelConfig = ModelConfigManager.shared
    @AppStorage("agentEnabled") private var agentEnabled = false
    @AppStorage("agentDebugModeEnabled") private var debugModeEnabled = false
    @AppStorage("selectedAgentType") private var selectedAgentType = AgentType.jules.rawValue

    private let registry = AIProviderRegistry.shared

    var selectedProvider: (any AIProvider)? {
        registry.provider(for: settings.selectedProviderID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    aboutSectionContent
                } header: {
                    Label("Workspace AI Platform", systemImage: "info.circle.fill")
                }

                Section {
                    providerSectionContent
                    modelSectionContent
                    aiUsageSectionContent
                } header: {
                    Label("Engine & Connectivity", systemImage: "cpu.fill")
                }

                Section {
                    systemPromptSectionContent
                } header: {
                    Label("System Instructions", systemImage: "terminal.fill")
                }

                Section {
                    personalitySectionContent
                    expertiseSectionContent
                    styleSectionContent
                } header: {
                    Label("Personality & Voice", systemImage: "person.wave.2.fill")
                }

                Section {
                    contextSectionContent
                } header: {
                    Label("Knowledge & Intelligence", systemImage: "brain.fill")
                }

                Section {
                    NavigationLink(destination: SkillsView()) {
                        Label {
                            HStack {
                                Text("Injected Capabilities")
                                Spacer()
                                Text("\(skillsManager.skills.count) Active")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                        } icon: {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    memorySectionContent
                    agentSettingsSectionContent
                } header: {
                    Label("Advanced Automation", systemImage: "wand.and.stars")
                }

                Section {
                    chatInterfaceSectionContent
                    appModeSectionContent
                } header: {
                    Label("Visual Experience", systemImage: "paintbrush.fill")
                }

                Section {
                    advancedSectionContent
                    storageSectionContent
                } header: {
                    Label("Runtime Config", systemImage: "slider.horizontal.3")
                }

                Section {
                    cloudDataSectionContent
                    accountSectionContent
                } header: {
                    Label("User Identity", systemImage: "person.crop.circle.badge.checkmark")
                }

                Section {
                    developerToolsSectionContent
                } header: {
                    Label("SDK Debugging", systemImage: "hammer.fill")
                }
            }
            .task {
                await loadProviderModels(force: false)
                await MainActor.run { featureCheck.refresh() }
            }
            .onChange(of: settings.selectedProviderID) { _, _ in
                Task { await loadProviderModels(force: false) }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var providerSectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            if let provider = selectedProvider {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: provider.icon)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.name)
                                .font(.headline)
                            if let url = provider.apiKeyURL {
                                Link("Get API Key", destination: url)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    APIKeyRowView(
                        providerID: provider.id,
                        providerName: provider.name,
                        placeholder: provider.apiKeyPlaceholder
                    )
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var aiUsageSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Model Source", selection: $settings.aiModelSource) {
                ForEach(AIModelSource.allCases, id: \.self) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Image(systemName: settings.aiModelSource == .ownKey ? "checkmark.shield.fill" : "bolt.badge.clock.fill")
                    .foregroundColor(settings.aiModelSource == .ownKey ? .green : .blue)

                VStack(alignment: .leading) {
                    Text(featureCheck.usageMessage())
                        .font(.subheadline.bold())
                    Text(settings.aiModelSource == .ownKey ? "Unlimited Personal Usage" : "10 Free Daily Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((settings.aiModelSource == .ownKey ? Color.green : Color.blue).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var modelSectionContent: some View {
        Group {
            let availableModels = modelCatalog.models(for: settings.selectedProviderID)
            if !availableModels.isEmpty {
                Picker("Active Model", selection: $settings.modelID) {
                    ForEach(availableModels) { model in
                        HStack {
                            Text(model.name)
                            if model.supportsVision {
                                Image(systemName: "eye.fill").foregroundColor(.blue).font(.caption)
                            }
                        }
                        .tag(model.id)
                    }
                }
                .pickerStyle(.navigationLink)
            } else {
                HStack {
                    ProgressView().padding(.trailing, 8)
                    Text("Fetching Models...")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var systemPromptSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Source Mode", selection: Binding(
                get: { settings.selectedPresetID != nil ? 0 : 1 },
                set: { mode in
                    if mode == 0 {
                        settings.selectedPresetID = SystemPromptPreset.builtIn.first?.id
                    } else {
                        settings.selectedPresetID = nil
                    }
                }
            )) {
                Text("Predefined Templates").tag(0)
                Text("Manual Instructions").tag(1)
            }
            .pickerStyle(.segmented)

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
                    .padding(.vertical, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $settings.systemPrompt)
                        .frame(minHeight: 140)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    HStack {
                        Button("Optimize Prompt") { /* AI Logic */ }
                        Spacer()
                        Button("Restore Default") { settings.systemPrompt = "You are a helpful assistant." }
                    }
                    .font(.caption2.bold())
                }
            }

            DisclosureGroup("Dynamic Injection Tokens") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reference workspace data using bracket notation:").font(.system(size: 10)).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        TokenBadge(text: "{user_profile}")
                        TokenBadge(text: "{active_project}")
                        TokenBadge(text: "{recent_events}")
                        TokenBadge(text: "{sdk_docs}")
                        TokenBadge(text: "{current_task}")
                        TokenBadge(text: "{local_time}")
                    }
                }
                .padding(.vertical, 8)
            }

            Toggle("Append Safety Guardrails", isOn: .constant(true))
                .font(.caption)
        }
    }

    private struct TokenBadge: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.system(size: 9, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private var personalitySectionContent: some View {
        Group {
            Toggle("Custom Personality", isOn: $settings.useCustomPersonality)
            if settings.useCustomPersonality {
                TextField("Name", text: $settings.personalityName)
                TagEditorView(tags: $settings.personalityTraits, placeholder: "Add Trait (e.g. Creative, Analytical)")
            }
        }
    }

    private var expertiseSectionContent: some View {
        TagEditorView(tags: $settings.expertiseAreas, placeholder: "Add Expertise (e.g. Swift, Python)")
    }

    private var styleSectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Response Tone").font(.caption2.bold()).foregroundStyle(.secondary)
                Picker("Tone", selection: $settings.responseTone) {
                    ForEach(ResponseTone.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Interactive Voice Preview").font(.system(size: 9, weight: .black)).foregroundStyle(.blue).textCase(.uppercase)
                Text(tonePreviewText)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.1), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Verbosity & Detail").font(.caption2.bold()).foregroundStyle(.secondary)
                Picker("Length", selection: $settings.preferredResponseLength) {
                    ForEach(ResponseLength.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Behavioral Controls").font(.caption2.bold()).foregroundStyle(.secondary)
                Toggle("Use Emojis", isOn: .constant(true))
                Toggle("Technical Depth", isOn: .constant(false))
                Toggle("Socratic Method", isOn: .constant(false))
            }
            .font(.subheadline)
        }
    }

    private var contextSectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Active Intelligence Sync", isOn: .constant(true))
                    .font(.headline)
                Text("Allows the model to reason across your entire workspace including documents, emails, and project files.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Manual Knowledge Buffer").font(.caption2.bold()).foregroundStyle(.secondary)
                TextEditor(text: $settings.knowledgeContext)
                    .frame(height: 120)
                    .font(.system(size: 11))
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button { settings.knowledgeContext = "" } label: {
                    Label("Flush", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button { showFileImporter = true } label: {
                    Label("Add PDF/TXT", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Connected Sources").font(.caption2.bold()).foregroundStyle(.secondary)
                KnowledgeSourceRow(name: "SDK Documentation", icon: "book.fill", isSynced: true)
                KnowledgeSourceRow(name: "Workspace Files", icon: "folder.fill", isSynced: true)
                KnowledgeSourceRow(name: "External Web", icon: "globe", isSynced: false)
            }
        }
    }

    private struct KnowledgeSourceRow: View {
        let name: String
        let icon: String
        let isSynced: Bool
        var body: some View {
            HStack {
                Label(name, systemImage: icon).font(.caption)
                Spacer()
                Text(isSynced ? "SYNCED" : "OFFLINE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(isSynced ? .green : .secondary)
            }
        }
    }

    private var aboutSectionContent: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.blue.gradient)
                .padding(.top)

            VStack(spacing: 4) {
                Text("ToolsKit AI").font(.headline)
                Text("Version 2.4.5 (Build 2026.12)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Text("A state-of-the-art AI assistant integrated directly into your Workspace, designed for high-performance productivity and seamless automation.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 20) {
                Link(destination: URL(string: "https://toolskit.io")!) {
                    Label("Website", systemImage: "network")
                }
                Link(destination: URL(string: "https://twitter.com/toolskit")!) {
                    Label("Twitter", systemImage: "bird")
                }
            }
            .font(.caption2)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
    }

    private var tonePreviewText: String {
        switch settings.responseTone {
        case .formal: return "I would be delighted to assist you with your request in a professional manner."
        case .casual: return "Hey! I'm totally down to help you out with that. What's up?"
        case .concise: return "Understood. Proceeding with the requested task immediately."
        case .creative: return "Imagine a world where your ideas take flight on the wings of artificial intelligence..."
        default: return "Sample response text will appear here."
        }
    }

    private var memorySectionContent: some View {
        Group {
            Toggle("Enable Long-term Memory", isOn: $settings.memoryEnabled)
            if settings.memoryEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sensitivity: \(settings.memorySensitivity, specifier: "%.2f")")
                    Slider(value: $settings.memorySensitivity, in: 0.2...1.0)
                }
                NavigationLink("Manage Memories") {
                    MemoryManagerView(memoryStore: memoryStore)
                }
            }
        }
    }

    private var advancedSectionContent: some View {
        Group {
            VStack(alignment: .leading) {
                Text("Temperature: \(settings.temperature, specifier: "%.1f")")
                Slider(value: $settings.temperature, in: 0...2, step: 0.1)
            }
            Stepper("Max Tokens: \(settings.maxTokens)", value: $settings.maxTokens, in: 256...8192, step: 256)
        }
    }

    private var chatInterfaceSectionContent: some View {
        Group {
            ColorPickerRow(label: "Bubble Color", hexColor: $settings.bubbleColorHex)
            VStack(alignment: .leading) {
                Text("Font Size: \(Int(settings.fontSize))pt")
                Slider(value: $settings.fontSize, in: 12...22, step: 1)
            }
            Toggle("Show Timestamps", isOn: $settings.showTimestamps)
        }
    }

    private var storageSectionContent: some View {
        Group {
            Toggle("Save History", isOn: $settings.saveChatHistory)
            Toggle("Stream Responses", isOn: $settings.streamResponseText)
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
                Label(currentMode.title, systemImage: currentMode.icon)
                Spacer()
                Text("Change Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var cloudDataSectionContent: some View {
        Button {
            uploadDataToCloud()
        } label: {
            HStack {
                if isUploadingToCloud { ProgressView().padding(.trailing, 8) }
                Text(isUploadingToCloud ? "Syncing..." : "Sync to Cloud")
            }
        }
        .disabled(isUploadingToCloud)
    }

    private var accountSectionContent: some View {
        Button(role: .destructive) {
            signOutCurrentUser()
        } label: {
            Text("Sign Out")
        }
    }

    private var developerToolsSectionContent: some View {
        Group {
            NavigationLink("SiriGlowCore UI Playground") { SiriCoreUIView() }
            NavigationLink("Model Config") { modelConfigSheet }
            if debugModeEnabled {
                NavigationLink("Agent Config") { AgentConfigView() }
            }
            NavigationLink {
                AgenticUIDebugPanel()
                    .navigationTitle("Foundation Models")
            } label: {
                Label("Check Foundation Models Availability", systemImage: "cpu")
            }
        }
    }

    // MARK: - Private Methods

    private var modelConfigSheet: some View {
        Form {
            Section("Endpoints") {
                TextField("Reasoning", text: $modelConfig.reasoningModel)
                TextField("Vision", text: $modelConfig.visionModel)
                TextField("Language", text: $modelConfig.languageModel)
            }
        }
        .navigationTitle("Model Config")
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

    private func uploadDataToCloud() {
        isUploadingToCloud = true
        Task {
            do {
                try await UserDataManager.shared.uploadCurrentUserData()
                await MainActor.run { isUploadingToCloud = false }
            } catch {
                await MainActor.run { isUploadingToCloud = false }
            }
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

extension AIChatSettingsView {
    enum AppMode: String, CaseIterable, Identifiable {
        case dashboard, music, workouts, workspace
        var id: String { rawValue }
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .music: return "Music"
            case .workouts: return "Workouts"
            case .workspace: return "Workspace"
            }
        }
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .music: return "music.note.list"
            case .workouts: return "figure.strengthtraining.traditional"
            case .workspace: return "rectangle.3.group"
            }
        }
        var tint: Color {
            switch self {
            case .dashboard: return .blue
            case .music: return .pink
            case .workouts: return .mint
            case .workspace: return .indigo
            }
        }
        var description: String {
            switch self {
            case .dashboard: return "Standard tools & dashboard"
            case .music: return "Music player experience"
            case .workouts: return "AI fitness tracking"
            case .workspace: return "Production workspace"
            }
        }
    }

    var currentMode: AppMode {
        if musicMode.isMusicModeEnabled { return .music }
        if workoutsMode.isWorkoutsModeEnabled { return .workouts }
        if workspaceMode.isWorkspaceModeEnabled { return .workspace }
        return .dashboard
    }

    var selectedAppMode: Binding<AppMode> {
        Binding(
            get: { currentMode },
            set: { newMode in
                musicMode.isMusicModeEnabled = (newMode == .music)
                workoutsMode.isWorkoutsModeEnabled = (newMode == .workouts)
                workspaceMode.isWorkspaceModeEnabled = (newMode == .workspace)
            }
        )
    }
}

// MARK: - Supporting Views

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
            TagFlowLayout(tags: tags) { tag in
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

struct TagFlowLayout<Content: View>: View {
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
