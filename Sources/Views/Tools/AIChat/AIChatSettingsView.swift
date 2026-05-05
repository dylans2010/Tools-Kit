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
    @State private var isUploadingToCloud = false
    @State private var cloudStatusMessage: String?
    @State private var isSigningOut = false
    @State private var signOutStatusMessage: String?
    @State private var showFreeOpenRouterSheet = false
    @State private var showFileImporter = false
    @State private var importedFileNames: [String] = []
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
                providerSection
                aiUsageSection
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
                agentSettingsSection
                appModeSection
                keyboardExtensionSection
                toolVisibilitySection
                supportSection
                developerToolsSection
                internalSection
                cloudDataSection
                accountSection
            }
            .task {
                await loadProviderModels(force: false)
                await MainActor.run { featureCheck.refresh() }
            }
            .onChange(of: settings.selectedProviderID) { _, _ in
                Task { await loadProviderModels(force: false) }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFileImporter) {
                FileImporterView(allowedContentTypes: [.data, .content, .item], allowsMultipleSelection: true) { urls in
                    self.importedFileNames = urls.map { $0.lastPathComponent }
                }
            }
            .sheet(isPresented: $showFreeOpenRouterSheet) {
                NavigationStack {
                    List(freeOpenRouterModels) { model in
                        Button {
                            settings.modelID = model.id
                            showFreeOpenRouterSheet = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(model.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .navigationTitle("Free OpenRouter Models")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showFreeOpenRouterSheet = false }
                        }
                    }
                }
            }
        }
    }

    private var internalSection: some View {
        Section("Internal (Debug)") {
            Button {
                showFileImporter = true
            } label: {
                Label("Test File Importer", systemImage: "doc.badge.plus")
            }

            if !importedFileNames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Imported Files:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(importedFileNames, id: \.self) { name in
                        Text(name)
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var agentSettingsSection: some View {
        Section("Agent (Beta)") {
            Toggle("Use System Tools", isOn: $settings.useSystemTools)
            Toggle("Agent", isOn: $agentEnabled)
                .help("Choose which agent handles your sessions")
            if agentEnabled {
                Picker("Agent Type", selection: $selectedAgentType) {
                    Text("System").tag(AgentType.system.rawValue)
                    Text("Jules").tag(AgentType.jules.rawValue)
                }
                .pickerStyle(.segmented)
            }
            let jules = JulesProvider.apiProviderInfo
            APIKeyRowView(
                providerID: jules.id,
                providerName: jules.name,
                placeholder: jules.apiKeyPlaceholder
            )
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
            .scrollClipDisabled()

            if let provider = selectedProvider {
                HStack(spacing: 10) {
                    Image(systemName: provider.icon)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(provider.name) Selected")
                            .font(.subheadline.weight(.semibold))
                        Text("Keys are stored per provider and preserved when switching.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private var aiUsageSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Model Source", selection: $settings.aiModelSource) {
                    ForEach(AIModelSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Label(featureCheck.usageMessage(), systemImage: settings.aiModelSource == .ownKey ? "checkmark.shield" : "bolt.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.aiModelSource == .ownKey ? .green : .blue)

                    HStack(spacing: 8) {
                        Text(settings.aiModelSource == .ownKey ? "Unlimited Requests" : "Daily Limit Reached")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((settings.aiModelSource == .ownKey ? Color.green : Color.blue).opacity(0.12))
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("AI Usage")
        } footer: {
            Text("App Model uses the cloud for any AI tasks which you will be limited to 10 tasks a day. Your own API key will be fully controlled by you.")
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
                            Label("Vision Supported", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if let ctx = model.contextLength {
                            Spacer()
                            Text("\(ctx / 1000)K Context")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if settings.selectedProviderID == "openrouter", model.name.localizedCaseInsensitiveContains("free") || model.id.localizedCaseInsensitiveContains("free") {
                        Button {
                            showFreeOpenRouterSheet = true
                        } label: {
                            Label("Browse Free OpenRouter Models", systemImage: "list.bullet.rectangle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else if modelCatalog.loadingProviders.contains(settings.selectedProviderID) {
                HStack {
                    ProgressView()
                    Text("Loading Models…")
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
            TagEditorView(tags: $settings.expertiseAreas, placeholder: "Add Expertise")
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
            Toggle("Enable Streaming (Experimental)", isOn: $settings.streamResponseText)
        }
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        Section("Memory (CoreML Powered)") {
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

    // MARK: - App Mode Section

    private var keyboardExtensionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Keyboard (Beta)", systemImage: "keyboard")
                    .font(.headline)

                Text("Enable the ToolsKit keyboard to get AI writing assistance in any app.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open System Settings")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding(.vertical, 4)

            NavigationLink {
                VStack(spacing: 20) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("How to Enable")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        StepView(number: 1, text: "Open iOS Settings")
                        StepView(number: 2, text: "Go to General > Keyboard > Keyboards")
                        StepView(number: 3, text: "Tap 'Add New Keyboard...'")
                        StepView(number: 4, text: "Select 'ToolsKit'")
                        StepView(number: 5, text: "Tap 'ToolsKit' and enable 'Allow Full Access'")
                    }
                    .padding()

                    Spacer()
                }
                .padding()
                .navigationTitle("Keyboard Setup")
            } label: {
                Label("Setup Instructions", systemImage: "info.circle")
            }
        } header: {
            Text("Keyboard")
        } footer: {
            Text("Full access is required for AI features like rewriting and smart suggestions.")
        }
    }

    private var appModeSection: some View {
        Section {
            Picker("Mode", selection: selectedAppMode) {
                ForEach(AppMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.navigationLink)
            .disabled(musicMode.isLocked)

            HStack(spacing: 12) {
                Image(systemName: currentMode.icon)
                    .foregroundColor(currentMode.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMode.title)
                        .font(.subheadline.weight(.semibold))
                    Text(currentMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            if musicMode.isLocked {
                Text("Music mode is locked because the app bundle identifier contains 'music'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Turn ToolsKit Into")
        } footer: {
            Text("Choose the launch experience for ToolsKit. Only one mode can be active at a time.")
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


    private var developerToolsSection: some View {
        Section("Developer") {
            NavigationLink("Developer Tools") {
                MeetDeveloperToolsView(manager: .shared)
            }
            NavigationLink("Feedback Admin") {
                FeedbackAdminView(allowDeveloperToolsAccess: true)
            }
            if debugModeEnabled {
                NavigationLink {
                    AgentConfigView()
                } label: {
                    Label("Agent Config (Debug)", systemImage: "ant.fill")
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink("Send Feedback") {
                FeedbackView()
            }
        }
    }

    private var cloudDataSection: some View {
        Section("Cloud Sync") {
            Button {
                uploadDataToCloud()
            } label: {
                HStack {
                    if isUploadingToCloud {
                        ProgressView()
                    }
                    Text(isUploadingToCloud ? "Uploading..." : "Upload Data To Cloud")
                }
            }
            .disabled(isUploadingToCloud)

            if let cloudStatusMessage {
                Text(cloudStatusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button(role: .destructive) {
                signOutCurrentUser()
            } label: {
                HStack {
                    if isSigningOut {
                        ProgressView()
                    }
                    Text(isSigningOut ? "Signing Out..." : "Sign Out")
                }
            }
            .disabled(isSigningOut)

            if let signOutStatusMessage {
                Text(signOutStatusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

    private func uploadDataToCloud() {
        isUploadingToCloud = true
        cloudStatusMessage = nil
        Task {
            do {
                try await UserDataManager.shared.uploadCurrentUserData()
                await MainActor.run {
                    cloudStatusMessage = "Data uploaded to cloud."
                    isUploadingToCloud = false
                }
            } catch {
                await MainActor.run {
                    cloudStatusMessage = "Upload failed: \(error.localizedDescription)"
                    isUploadingToCloud = false
                }
            }
        }
    }

    private func signOutCurrentUser() {
        isSigningOut = true
        signOutStatusMessage = nil
        Task {
            do {
                try await AccountAuthService.shared.signOut()
                await MainActor.run {
                    signOutStatusMessage = "Signed Out"
                    isSigningOut = false
                    onSignOut?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    signOutStatusMessage = "Sign out failed: \(error.localizedDescription)"
                    isSigningOut = false
                }
            }
        }
    }
}

private extension AIChatSettingsView {
    enum AppMode: String, CaseIterable, Identifiable {
        case dashboard
        case music
        case workouts
        case workspace

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Default Dashboard"
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
            case .dashboard: return "Launch into the standard dashboard with all tools."
            case .music: return "Replace the dashboard with the Music player experience."
            case .workouts: return "Launch into AI-powered fitness tracking and plans."
            case .workspace: return "Launch into Notes, Forms, and Slides workspace."
            }
        }
    }

    var freeOpenRouterModels: [AIModel] {
        modelCatalog.models(for: "openrouter")
            .filter { $0.name.localizedCaseInsensitiveContains("free") || $0.id.localizedCaseInsensitiveContains("free") }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
                if musicMode.isLocked {
                    musicMode.isMusicModeEnabled = true
                    workoutsMode.isWorkoutsModeEnabled = false
                    workspaceMode.isWorkspaceModeEnabled = false
                    return
                }

                switch newMode {
                case .dashboard:
                    musicMode.isMusicModeEnabled = false
                    workoutsMode.isWorkoutsModeEnabled = false
                    workspaceMode.isWorkspaceModeEnabled = false
                case .music:
                    musicMode.isMusicModeEnabled = true
                    workoutsMode.isWorkoutsModeEnabled = false
                    workspaceMode.isWorkspaceModeEnabled = false
                case .workouts:
                    musicMode.isMusicModeEnabled = false
                    workoutsMode.isWorkoutsModeEnabled = true
                    workspaceMode.isWorkspaceModeEnabled = false
                case .workspace:
                    musicMode.isMusicModeEnabled = false
                    workoutsMode.isWorkoutsModeEnabled = false
                    workspaceMode.isWorkspaceModeEnabled = true
                }
            }
        )
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
                    .foregroundStyle(isSelected ? .white : .blue)
                Text(provider.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
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

struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))

            Text(text)
                .font(.subheadline)

            Spacer()
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
