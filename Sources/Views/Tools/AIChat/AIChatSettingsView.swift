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
    @StateObject private var diagnosticsMode = DiagnosticsModeManager.shared
    @StateObject private var gamesMode = GamesModeManager.shared
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
    @StateObject private var connectionManager = LMConnectionManager.shared
    @AppStorage("agentEnabled") private var agentEnabled = false
    @AppStorage("agentDebugModeEnabled") private var debugModeEnabled = false
    @AppStorage("selectedAgentType") private var selectedAgentType = AgentType.jules.rawValue
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""
    @State private var currentAppMode: AppMode = .dashboard

    private let registry = AIProviderRegistry.shared

    var selectedProvider: (any AIProvider)? {
        registry.provider(for: selectedProviderID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        providerSectionContent
                    } header: {
                        Label("AI Provider", systemImage: "cpu")
                    }

                    Section {
                        aiUsageSectionContent
                    } header: {
                        Label("AI Usage", systemImage: "bolt.fill")
                    }

                    Section {
                        modelSectionContent
                    } header: {
                        Label("Model Configuration", systemImage: "cube.fill")
                    }

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
                }

                Group {
                    Section {
                        systemPromptSectionContent
                    } header: {
                        Label("System Prompt", systemImage: "terminal.fill")
                    }

                    Section {
                        systemPromptToolsSectionContent
                    } header: {
                        Label("Prompt Tools", systemImage: "wrench.and.screwdriver")
                    }

                    Section {
                        personalitySectionContent
                        expertiseSectionContent
                        styleSectionContent
                        personalityToolsSectionContent
                    } header: {
                        Label("AI Personality & Tone", systemImage: "person.fill")
                    }

                    Section {
                        contextSectionContent
                        contextToolsSectionContent
                    } header: {
                        Label("Knowledge & Context", systemImage: "book.fill")
                    }
                }

                Group {
                    Section {
                        memorySectionContent
                    } header: {
                        Label("Memory", systemImage: "brain.head.profile")
                    }

                    Section {
                        advancedSectionContent
                    } header: {
                        Label("Advanced Parameters", systemImage: "slider.horizontal.3")
                    }
                }

                Group {
                    Section {
                        chatInterfaceSectionContent
                    } header: {
                        Label("Interface", systemImage: "paintbrush.fill")
                    }

                    Section {
                        storageSectionContent
                    } header: {
                        Label("Data Management", systemImage: "tray.full.fill")
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
                        cloudDataSectionContent
                        accountSectionContent
                    } header: {
                        Label("Account & Sync", systemImage: "person.crop.circle.fill")
                    }

                    Section {
                        developerToolsSectionContent
                    } header: {
                        Label("Developer Settings", systemImage: "hammer.fill")
                    }

                    Section {
                NavigationLink(destination: FeedbackMainView()) {
                    Label("Feedback & Support", systemImage: "heart.text.square.fill")
                        .foregroundColor(.pink)
                }
                        aboutSectionContent
                    } header: {
                        Label("About", systemImage: "info.circle.fill")
                    }
                }
            }
            .task {
                await loadProviderModels(force: false)
                await MainActor.run { featureCheck.refresh() }
            }
            .onAppear {
                currentAppMode = resolveCurrentMode()
            }
            .onChange(of: musicMode.isMusicModeEnabled) { _, _ in currentAppMode = resolveCurrentMode() }
            .onChange(of: workoutsMode.isWorkoutsModeEnabled) { _, _ in currentAppMode = resolveCurrentMode() }
            .onChange(of: workspaceMode.isWorkspaceModeEnabled) { _, _ in currentAppMode = resolveCurrentMode() }
            .onChange(of: diagnosticsMode.isDiagnosticsModeEnabled) { _, _ in currentAppMode = resolveCurrentMode() }
            .onChange(of: gamesMode.isGamesModeEnabled) { _, _ in currentAppMode = resolveCurrentMode() }
            .onChange(of: selectedProviderID) { _, newValue in
                settings.selectedProviderID = newValue
                Task { await loadProviderModels(force: false) }
            }
            .onChange(of: modelID) { _, newValue in
                settings.modelID = newValue
            }
            .navigationTitle("Settings")
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
                            isSelected: selectedProviderID == provider.id
                        ) {
                            selectedProviderID = provider.id
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

                    if provider.id == "local_models" || provider.id == "lmstudio" {
                        NavigationLink(destination: SetupLocalModelsView()) {
                            Label("Configure Local System", systemImage: "gearshape.fill")
                                .foregroundColor(.blue)
                        }
                    } else {
                        APIKeyRowView(
                            providerID: provider.id,
                            providerName: provider.name,
                            placeholder: provider.apiKeyPlaceholder
                        )
                    }
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
        VStack(alignment: .leading, spacing: 12) {
            if settings.aiModelSource == .local {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local Model Configuration")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connectionManager.selectedModel?.id ?? "No model selected")
                                .font(.headline)
                            if let device = connectionManager.selectedDevice {
                                Text("Running on \(device.ipAddress):\(device.port)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                    NavigationLink(destination: LMDeviceFallbackView()) {
                        Label("Change Local Device", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            } else if ["local_models", "afm", "lmstudio"].contains(selectedProviderID) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current AI Model:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(modelID.isEmpty ? "No model selected" : modelID)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            } else {
                let availableModels = modelCatalog.models(for: selectedProviderID)
                if !availableModels.isEmpty {
                    Picker("Active Model", selection: $modelID) {
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

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Models")
                        .font(.caption.bold())
                    TextField("Model ID or Endpoint", text: $modelID)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Text("This model will be used by all AI powered features inside ToolsKit.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            if settings.selectedProviderID == "openrouter" {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    Toggle(isOn: $settings.dynamicRoutingEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dynamic AI Routing")
                                .font(.headline)
                            Text("Automatically switches between free models to prevent interruptions from rate limits or failures. Note this can take longer to respond.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: OpenRouterFreeModelsView(selectedModelID: $settings.modelID)) {
                        Label {
                            Text("Browse Free Models")
                        } icon: {
                            Image(systemName: "tray.full.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var systemPromptSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                TextEditor(text: $settings.systemPrompt)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }
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
        Group {
            Picker("Tone", selection: $settings.responseTone) {
                ForEach(ResponseTone.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Picker("Length", selection: $settings.preferredResponseLength) {
                ForEach(ResponseLength.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
        }
    }

    private var contextSectionContent: some View {
        Group {
            TextEditor(text: $settings.knowledgeContext)
                .frame(minHeight: 80)

            Toggle("Auto-= Inject App Context", isOn: $settings.autoInjectContext)
            Toggle("Include Conversation History", isOn: $settings.includeConversationHistory)
        }
    }

    private var contextToolsSectionContent: some View {
        Group {
            NavigationLink {
                FileContextManagerView(settings: $settings)
            } label: {
                Label("File Context Sources", systemImage: "doc.badge.plus")
            }

            NavigationLink {
                WebContextManagerView(settings: $settings)
            } label: {
                Label("Web Context Sources", systemImage: "globe")
            }

            NavigationLink {
                RAGSettingsView(settings: $settings)
            } label: {
                Label("RAG Settings", systemImage: "magnifyingglass.circle")
            }

            NavigationLink {
                EmbeddingConfigView(settings: $settings)
            } label: {
                Label("Embedding Configuration", systemImage: "point.3.connected.trianglepath.dotted")
            }

            NavigationLink {
                ContextWindowView(settings: $settings)
            } label: {
                Label("Context Window Manager", systemImage: "rectangle.split.3x1")
            }
        }
    }

    private var systemPromptToolsSectionContent: some View {
        Group {
            NavigationLink {
                PromptTemplateLibraryView()
            } label: {
                Label("Prompt Template Library", systemImage: "doc.text.below.ecg")
            }

            NavigationLink {
                PromptVariablesView(settings: $settings)
            } label: {
                Label("Dynamic Variables", systemImage: "curlybraces")
            }

            NavigationLink {
                PromptChainEditorView(settings: $settings)
            } label: {
                Label("Prompt Chain Editor", systemImage: "link.badge.plus")
            }

            NavigationLink {
                PromptVersionHistoryView()
            } label: {
                Label("Version History", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    private var personalityToolsSectionContent: some View {
        Group {
            NavigationLink {
                ResponseFormatterView(settings: $settings)
            } label: {
                Label("Response Formatting Rules", systemImage: "textformat.abc")
            }

            NavigationLink {
                LanguageSettingsView(settings: $settings)
            } label: {
                Label("Language & Locale", systemImage: "globe.americas")
            }

            NavigationLink {
                OutputConstraintsView(settings: $settings)
            } label: {
                Label("Output Constraints", systemImage: "ruler")
            }

            NavigationLink {
                PersonalityPresetsView()
            } label: {
                Label("Personality Presets", systemImage: "person.2.crop.square.stack")
            }

            NavigationLink {
                ToneSamplerView()
            } label: {
                Label("Tone Sampler", systemImage: "waveform")
            }
        }
    }

    private var aboutSectionContent: some View {
        Group {
            LabeledContent("App Name", value: "Tools Kit")
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build", value: "2026.5")
            LabeledContent("Platform", value: "iOS / iPadOS")
            LabeledContent("Developer", value: "Dylan")
            LabeledContent("Framework", value: "SwiftUI")

            NavigationLink {
                LicensesView()
            } label: {
                Label("Open Source Licenses", systemImage: "doc.plaintext")
            }

            NavigationLink {
                ChangelogView()
            } label: {
                Label("Changelog", systemImage: "list.bullet.rectangle")
            }

            if let privacyURL = URL(string: "https://toolskit.io/privacy") {
                Link(destination: privacyURL) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }

            if let termsURL = URL(string: "https://toolskit.io/terms") {
                Link(destination: termsURL) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
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
                Label(currentAppMode.title, systemImage: currentAppMode.icon)
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
            NavigationLink("Local Logs") { LMStudioLogsView() }
            NavigationLink("Device Bridge") { BridgeHomeView() }
            NavigationLink("Audio Debugger") { AudioDebugView() }
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
        let providerID = selectedProviderID
        await modelCatalog.loadModels(for: providerID, force: force)
        let models = await MainActor.run { modelCatalog.models(for: providerID) }
        await MainActor.run {
            if !models.contains(where: { $0.id == modelID }) {
                modelID = models.first?.id ?? ""
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

// MARK: - Context Tool Views

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
                            Toggle("", isOn: Binding(
                                get: { source.isActive },
                                set: { val in
                                    if let idx = settings.fileSources.firstIndex(where: { $0.id == source.id }) {
                                        settings.fileSources[idx].isActive = val
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                    .onDelete { settings.fileSources.remove(atOffsets: $0) }
                }
            }
            Section("Add Source") {
                HStack {
                    TextField("File path or bundle resource", text: $newSource)
                    Button("Add") {
                        guard !newSource.isEmpty else { return }
                        settings.fileSources.append(FileSource(path: newSource))
                        newSource = ""
                    }
                    .disabled(newSource.isEmpty)
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
                            Toggle("", isOn: Binding(
                                get: { source.isActive },
                                set: { val in
                                    if let idx = settings.webSources.firstIndex(where: { $0.id == source.id }) {
                                        settings.webSources[idx].isActive = val
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                    .onDelete { settings.webSources.remove(atOffsets: $0) }
                }
            }
            Section("Add URL") {
                HStack {
                    TextField("https://example.com/docs", text: $newURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Add") {
                        guard !newURL.isEmpty else { return }
                        settings.webSources.append(WebSource(url: newURL))
                        newURL = ""
                    }
                    .disabled(newURL.isEmpty)
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
                Picker("Search strategy", selection: $settings.ragSearchStrategy) {
                    Text("Semantic").tag("Semantic")
                    Text("Keyword").tag("Keyword")
                    Text("Hybrid").tag("Hybrid")
                }
            }
            Section("Chunking") {
                Stepper("Chunk Size: \(settings.ragChunkSize) Tokens", value: $settings.ragChunkSize, in: 128...2048, step: 128)
                Stepper("Chunk Overlap: \(settings.ragChunkOverlap) Tokens", value: $settings.ragChunkOverlap, in: 0...256, step: 32)
                Picker("Chunking Strategy", selection: $settings.ragChunkingStrategy) {
                    Text("Fixed").tag("Fixed")
                    Text("Sentence").tag("Sentence")
                    Text("Paragraph").tag("Paragraph")
                }
            }
        }
        .navigationTitle("RAG Settings")
    }
}

struct EmbeddingConfigView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Embedding Model") {
                Picker("Model", selection: $settings.embeddingModel) {
                    Text("Built In (Local)").tag("default")
                    Text("OpenAI text-embedding-3-small").tag("openai-small")
                    Text("OpenAI text-embedding-3-large").tag("openai-large")
                }
                LabeledContent("Dimensions", value: "\(settings.embeddingDimensions)")
                Toggle("Normalize Vectors", isOn: $settings.normalizeVectors)
            }
            Section("Storage") {
                Toggle("Compress Embeddings", isOn: $settings.compressEmbeddings)
            }
        }
        .navigationTitle("Embedding Config")
    }
}

struct ContextWindowView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Token Budget Allocation") {
                VStack(alignment: .leading) {
                    Text("System Prompt: \(Int(settings.contextAllocationSystemPrompt * 100))%")
                    Slider(value: $settings.contextAllocationSystemPrompt, in: 0.05...0.5)
                }
                VStack(alignment: .leading) {
                    Text("History: \(Int(settings.contextAllocationHistory * 100))%")
                    Slider(value: $settings.contextAllocationHistory, in: 0.1...0.8)
                }
                VStack(alignment: .leading) {
                    Text("RAG Context: \(Int(settings.contextAllocationRAG * 100))%")
                    Slider(value: $settings.contextAllocationRAG, in: 0.05...0.5)
                }
            }
            Section("Overflow Strategy") {
                Picker("When context exceeds limit", selection: $settings.contextOverflowStrategy) {
                    Text("Truncate oldest messages").tag("Truncate oldest")
                    Text("Summarize history").tag("Summarize")
                    Text("Drop RAG context first").tag("Drop RAG")
                }
                Toggle("Show warning on overflow", isOn: $settings.showContextOverflowWarning)
            }
        }
        .navigationTitle("Context Window")
    }
}

// MARK: - System Prompt Tool Views

struct PromptTemplateLibraryView: View {
    let templates = [
        ("Code Assistant", "Specialized for code review and generation"),
        ("Creative Writer", "Fiction, poetry, and creative content"),
        ("Data Analyst", "SQL, statistics, and data visualization"),
        ("Technical Writer", "Documentation and technical guides"),
        ("Tutor", "Patient explanations with examples"),
        ("Translator", "Multi-language translation assistant"),
        ("Summarizer", "Concise summaries of long content"),
        ("Debate Coach", "Structured argumentation practice"),
    ]

    var body: some View {
        List {
            ForEach(templates, id: \.0) { name, desc in
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.subheadline.bold())
                    Text(desc).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Prompt Templates")
    }
}

struct PromptVariablesView: View {
    @Binding var settings: AIChatSettings
    @State private var newName = ""
    @State private var newValue = ""

    var body: some View {
        Form {
            Section("Built-in Variables") {
                LabeledContent("{{date}}", value: "Current Date")
                LabeledContent("{{time}}", value: "Current Time")
                LabeledContent("{{user_name}}", value: "User's Name")
                LabeledContent("{{app_version}}", value: "App Version")
                LabeledContent("{{device_model}}", value: "Device Model")
            }
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
                    .disabled(newName.isEmpty)
                }
            }
        }
        .navigationTitle("Dynamic Variables")
    }
}

struct PromptChainEditorView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Prompt Chains") {
                if settings.promptChains.isEmpty {
                    Text("No Chains Defined").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(settings.promptChains) { chain in
                        Text(chain.name)
                    }
                    .onDelete { settings.promptChains.remove(atOffsets: $0) }
                }
                Button("Create New Chain") {
                    settings.promptChains.append(PromptChain(name: "New Chain", steps: []))
                }
            }
        }
        .navigationTitle("Prompt Chains")
    }
}

struct PromptVersionHistoryView: View {
    var body: some View {
        List {
            Text("No prompt versions saved yet.").font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("Version History")
    }
}

// MARK: - Personality Tool Views

struct ResponseFormatterView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Formatting Rules") {
                Toggle("Use Markdown formatting", isOn: $settings.useMarkdown)
                Toggle("Include code blocks", isOn: $settings.includeCodeBlocks)
                Toggle("Use bullet points for lists", isOn: $settings.useBulletPoints)
                Toggle("Add section headers", isOn: $settings.addSectionHeaders)
                Toggle("Include table of contents", isOn: $settings.includeTOC)
            }
            Section("Code Style") {
                Picker("Default language", selection: $settings.defaultCodeLanguage) {
                    Text("Swift").tag("Swift")
                    Text("Python").tag("Python")
                    Text("JavaScript").tag("JavaScript")
                    Text("TypeScript").tag("TypeScript")
                    Text("Auto-detect").tag("Auto")
                }
                Toggle("Show line numbers", isOn: $settings.showLineNumbers)
            }
        }
        .navigationTitle("Response Formatting")
    }
}

struct LanguageSettingsView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Response Language") {
                Picker("Primary language", selection: $settings.primaryLanguage) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("German").tag("German")
                }
                Toggle("Auto-detect input language", isOn: $settings.autoDetectLanguage)
                Toggle("Match response language", isOn: $settings.matchResponseLanguage)
            }
            Section("Locale") {
                Picker("Date format", selection: $settings.dateFormat) {
                    Text("System Default").tag("System")
                    Text("MM/DD/YYYY").tag("US")
                    Text("DD/MM/YYYY").tag("EU")
                }
                Picker("Number format", selection: $settings.numberFormat) {
                    Text("System Default").tag("System")
                    Text("1,000.00").tag("US")
                    Text("1.000,00").tag("EU")
                }
            }
        }
        .navigationTitle("Language & Locale")
    }
}

struct OutputConstraintsView: View {
    @Binding var settings: AIChatSettings
    var body: some View {
        Form {
            Section("Length Constraints") {
                Stepper("Max paragraphs: \(settings.maxParagraphs)", value: $settings.maxParagraphs, in: 1...50)
                Stepper("Max sentences per paragraph: \(settings.maxSentencesPerParagraph)", value: $settings.maxSentencesPerParagraph, in: 1...20)
                Toggle("Enforce word count limits", isOn: $settings.enforceWordCountLimits)
            }
            Section("Content Filters") {
                Toggle("Avoid technical jargon", isOn: $settings.avoidJargon)
                Toggle("Family-friendly content only", isOn: $settings.familyFriendlyOnly)
                Toggle("Cite sources when possible", isOn: $settings.citeSources)
                Toggle("Avoid opinions", isOn: $settings.avoidOpinions)
            }
        }
        .navigationTitle("Output Constraints")
    }
}

struct PersonalityPresetsView: View {
    let presets = [
        ("Professional", "person.crop.rectangle", Color.blue),
        ("Friendly", "face.smiling", Color.green),
        ("Academic", "graduationcap", Color.purple),
        ("Creative", "paintbrush.pointed", Color.orange),
        ("Concise", "text.alignleft", Color.gray),
        ("Socratic", "questionmark.circle", Color.indigo),
    ]

    var body: some View {
        List {
            ForEach(presets, id: \.0) { name, icon, color in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                        .frame(width: 36, height: 36)
                        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    Text(name).font(.subheadline.bold())
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Personality Presets")
    }
}

struct OpenRouterFreeModels: Identifiable {
    let id: String
    let name: String
}

struct OpenRouterFreeModelsView: View {
    @StateObject private var modelCatalog = AIModelCatalog.shared
    @Binding var selectedModelID: String

    var freeModels: [AIModel] {
        modelCatalog.models(for: "openrouter").filter { $0.id.lowercased().contains("free") }
    }

    var body: some View {
        List {
            if freeModels.isEmpty {
                Text("No free models found or still loading...")
                    .foregroundColor(.secondary)
            } else {
                ForEach(freeModels) { model in
                    Button {
                        selectedModelID = model.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name).font(.headline)
                                Text(model.id).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedModelID == model.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Browse Free Models")
    }
}

struct ToneSamplerView: View {
    @State private var sampleText = "Explain what an API is."
    @State private var selectedTone = "Neutral"
    @State private var response: String = ""
    @State private var isGenerating = false

    var body: some View {
        Form {
            Section("Sample Prompt") {
                TextEditor(text: $sampleText)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.1)))
            }
            Section("Tone") {
                Picker("Select tone", selection: $selectedTone) {
                    ForEach(["Neutral", "Formal", "Casual", "Humorous", "Empathetic", "Technical"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Button {
                    generatePreview()
                } label: {
                    HStack {
                        if isGenerating { ProgressView().padding(.trailing, 8) }
                        Text(isGenerating ? "Generating..." : "Generate Preview")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || sampleText.isEmpty)
            }

            if !response.isEmpty {
                Section("AI Response") {
                    Text(response)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Tone Sampler")
    }

    private func generatePreview() {
        isGenerating = true
        response = ""
        Task {
            do {
                let prompt = "Prompt: \(sampleText)\n\nPlease respond to the prompt above using a \(selectedTone) tone."
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run {
                    self.response = result
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.response = "Error: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - About Views

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
