import SwiftUI
import Aurora
import Speech
import AVFoundation
import AudioToolbox

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var activeModal: PersonaHomeModal?
    @State private var chatThreads: [PersonaChatThread] = []
    @State private var activeThreadID: UUID?
    @State private var pendingAction: PersonaAgentFramework.PersonaActionPreview?
    @State private var pendingIntent: PersonaAgentFramework.PersonaIntent?
    @State private var clarificationMissingField: String?
    @State private var showingFullScreenMCP = false

    enum PersonaHomeModal: Identifiable {
        case chats, settings, discovery, actions, exportOptions, voice
        case shareSheet(data: Data, filename: String)
        var id: String {
            switch self {
            case .chats: return "chats"
            case .settings: return "settings"
            case .discovery: return "discovery"
            case .actions: return "actions"
            case .exportOptions: return "exportOptions"
            case .voice: return "voice"
            case .shareSheet: return "shareSheet"
            }
        }
    }

    var body: some View {
        ZStack {
            PersonaHomeNavigationContent(
                chatHistory: manager.chatHistory,
                isThinking: manager.isThinking,
                agentMode: manager.agentModeEnabled,
                query: $query,
                pendingAction: pendingAction,
                onSend: sendMessage,
                onOpenDiscovery: { activeModal = .discovery },
                onOpenChats: { activeModal = .chats },
                onOpenActions: { activeModal = .actions },
                onOpenVoice: { activeModal = .voice },
                onConfirm: handleConfirmation(_:)
            )
        }
        .modifier(AILoadingModifier(isLoading: manager.isThinking))
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PersonaHomeToolbar(
                onShowTuning: { activeModal = .settings }
            )
        }
        .onAppear {
            if manager.chatHistory.isEmpty && !hasShownWelcome {
                activeModal = .discovery
                hasShownWelcome = true
            }
        }
        .sheet(item: $activeModal) { modal in
            PersonaHomeModalContent(
                modal: modal,
                manager: manager,
                onPromptSelection: { query = $0; sendMessage() },
                onThreadSelection: { thread in
                    activeThreadID = thread.id
                    manager.chatHistory = thread.messages
                },
                activeModal: $activeModal,
                showingFullScreenMCP: $showingFullScreenMCP,
                query: $query,
                onVoiceFinished: { sendMessage() }
            )
        }
        .fullScreenCover(isPresented: $showingFullScreenMCP) {
            NavigationStack {
                MCPMainView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingFullScreenMCP = false }
                        }
                    }
            }
        }
    }

    func sendMessage() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        query = ""
        Task { await manager.queryPersonaSafely(query: trimmed) }
    }

    private func handleConfirmation(_ confirmed: Bool) {
        guard confirmed, let intent = pendingIntent else { pendingAction = nil; pendingIntent = nil; return }
        Task {
            let result: PersonaAgentFramework.PersonaActionResult
            switch intent {
            case .deleteNote(let id): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteWorkspaceItem(id: id, type: .note)))
            case .deleteEvent(let p): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteEvent(parameters: p)))
            case .deleteTask(let id): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteTask(id: id)))
            default: result = .failed(error: .serviceUnavailable("Not implemented"))
            }
            pendingAction = nil
            pendingIntent = nil
        }
    }
}

// MARK: - Voice Input View

struct PersonaUserSpeak: View {
    @StateObject var speechManager = SpeechManager()
    @Binding var query: String
    var onFinished: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var hasTriggeredTalkChime = false

    var body: some View {
        ZStack {
            AuroraGlow(.subtle).palette(.appleIntelligence).ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text(speechManager.isRecording ? "Listening..." : "Voice Capture")
                        .font(.system(.title2, design: .rounded).bold())

                    if speechManager.isRecording {
                        Text("Persona is listening to your voice")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    DynamicWaveformView(audioLevel: speechManager.audioLevel)
                        .frame(width: 120, height: 80)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                        .offset(y: -50)
                        .opacity(speechManager.isRecording ? 1 : 0.5)
                }
                .padding(.vertical, 20)

                ScrollView {
                    Text(speechManager.transcription.isEmpty ? "Speak now..." : speechManager.transcription)
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 150)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))

                HStack(spacing: 20) {
                    Button {
                        playChime(soundID: 1050)
                        speechManager.stopRecording()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Button {
                        playChime(soundID: 1111)
                        query = speechManager.transcription
                        speechManager.stopRecording()
                        onFinished()
                        dismiss()
                    } label: {
                        Text("Send")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }
                    .disabled(speechManager.transcription.isEmpty)
                    .opacity(speechManager.transcription.isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(30)
        }
        .onChange(of: speechManager.transcription) { _, newValue in
            if !newValue.isEmpty && !hasTriggeredTalkChime {
                playChime(soundID: 1113)
                hasTriggeredTalkChime = true
            }
        }
        .onAppear {
            speechManager.checkPermissions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    try speechManager.startRecording()
                    playChime(soundID: 1110)
                } catch {
                    print("Failed to start recording: \(error)")
                }
            }
        }
        .onDisappear {
            speechManager.stopRecording()
        }
    }

    private func playChime(soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}

struct DynamicWaveformView: View {
    let audioLevel: Float

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<12) { i in
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: audioLevel)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 6
        let multiplier: CGFloat = 80
        // Add some randomness and vary based on index to look more "natural"
        let variation = CGFloat.random(in: 0.7...1.3)
        let indexWeight = 1.0 - abs(CGFloat(index - 6) / 6.0) // Center bars are taller
        return max(baseHeight, CGFloat(audioLevel) * multiplier * variation * indexWeight)
    }
}

// MARK: - Loading Modifier

struct AILoadingModifier: ViewModifier {
    let isLoading: Bool
    func body(content: Content) -> some View {
        if isLoading {
            content.aiAnimationLoading(true)
        } else {
            content
        }
    }
}

// MARK: - Subviews & Layout

private struct PersonaHomeNavigationContent: View {
    let chatHistory: [PersonaMessage]
    let isThinking: Bool
    let agentMode: Bool
    @Binding var query: String
    let pendingAction: PersonaAgentFramework.PersonaActionPreview?
    let onSend: () -> Void
    let onOpenDiscovery: () -> Void
    let onOpenChats: () -> Void
    let onOpenActions: () -> Void
    let onOpenVoice: () -> Void
    let onConfirm: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AuroraGlow(.subtle).palette(.appleIntelligence).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        List {
                            if chatHistory.isEmpty {
                                PersonaEmptyStateView(onDiscoverPrompts: onOpenDiscovery)
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            } else {
                                ForEach(chatHistory) { msg in
                                    PersonaChatBubble(message: msg).id(msg.id)
                                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                                }
                            }

                            MCPConnectStateList(invocations: MCPManager.shared.activeInvocations)
                                .listRowBackground(Color.clear).listRowSeparator(.hidden).id("mcp-list")

                            if isThinking {
                                ThinkingIndicator().id("thinking")
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)

                        if !chatHistory.isEmpty {
                            Button(action: {
                                withAnimation {
                                    if let id = chatHistory.last?.id {
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.blue)
                                    .background(Circle().fill(.background))
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .onChange(of: chatHistory.count) { _, _ in
                        withAnimation {
                            if let id = chatHistory.last?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isThinking) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }

            if let action = pendingAction {
                PersonaActionConfirmationCard(preview: action) { onConfirm($0) }
                    .padding().transition(.move(edge: .bottom)).zIndex(2)
            }

            // New Pill Input Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button(action: onOpenVoice) { Image(systemName: "mic.fill").font(.title3).foregroundStyle(.secondary) }
                    TextField("Message Persona...", text: $query, axis: .vertical)
                        .padding(.vertical, 8).lineLimit(1...5)

                    if !MCPManager.shared.servers.isEmpty {
                        Circle().fill(MCPManager.shared.servers.contains(where: { $0.connectionStatus == .connected }) ? Color.green : Color.gray).frame(width: 8, height: 8)
                    }

                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                            .foregroundStyle(query.isEmpty ? Color.secondary.opacity(0.3) : Color.blue)
                    }.disabled(query.isEmpty || isThinking)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(.ultraThinMaterial).clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Tuning Sheet (Functional)

struct TuningSheetView: View {
    @ObservedObject var manager: PersonaManager
    @Environment(\.dismiss) var dismiss
    let onExport: () -> Void
    @Binding var showingFullScreenMCP: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Persona Identity") {
                    TextField("Name", text: $manager.config.name)
                    Picker("Base Model", selection: $manager.config.baseModel) {
                        Text("GPT-4").tag("gpt-4")
                        Text("GPT-4o").tag("gpt-4o")
                        Text("Claude 3.5 Sonnet").tag("claude-3-5")
                        Text("Llama 3.1").tag("llama-3-1")
                    }
                    TextEditor(text: $manager.config.instructions).frame(height: 80)
                }
                Section("Personality Sliders") {
                    tuningSlider(label: "Creativity", value: $manager.config.creativity)
                    tuningSlider(label: "Formality", value: $manager.config.formality)
                    tuningSlider(label: "Humor", value: $manager.config.humor)
                    tuningSlider(label: "Conciseness", value: $manager.config.conciseness)
                    tuningSlider(label: "Detail Level", value: $manager.config.detailLevel)
                    tuningSlider(label: "Empathy", value: $manager.config.empathy)
                    tuningSlider(label: "Proactivity", value: $manager.config.proactivity)
                    tuningSlider(label: "Reasoning Depth", value: $manager.config.reasoningDepth)
                }
                Section("Advanced Parameters") {
                    tuningSlider(label: "Temperature", value: $manager.config.temperature)
                    tuningSlider(label: "Top P", value: $manager.config.topP)
                    tuningSlider(label: "Frequency Penalty", value: $manager.config.frequencyPenalty)
                    tuningSlider(label: "Presence Penalty", value: $manager.config.presencePenalty)

                    VStack(alignment: .leading) {
                        HStack { Text("Max Tokens"); Spacer(); Text("\(manager.config.maxTokens)") }
                        Slider(value: Binding(get: { Double(manager.config.maxTokens) }, set: { manager.config.maxTokens = Int($0) }), in: 256...4096, step: 128)
                    }
                    VStack(alignment: .leading) {
                        HStack { Text("Context Window"); Spacer(); Text("\(manager.config.contextWindow)") }
                        Slider(value: Binding(get: { Double(manager.config.contextWindow) }, set: { manager.config.contextWindow = Int($0) }), in: 1024...32768, step: 1024)
                    }
                }
                Section("Style & Language") {
                    Picker("Language", selection: $manager.config.language) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        Text("German").tag("German")
                        Text("Chinese").tag("Chinese")
                    }
                    Picker("Response Style", selection: $manager.config.responseStyle) {
                        Text("Balanced").tag("Balanced")
                        Text("Creative").tag("Creative")
                        Text("Precise").tag("Precise")
                    }
                    Picker("Coding Style", selection: $manager.config.codingStyle) {
                        Text("Standard").tag("Standard")
                        Text("Functional").tag("Functional")
                        Text("OOP").tag("OOP")
                    }
                    Picker("Search Engine", selection: $manager.config.searchEngine) {
                        Text("Google").tag("Google")
                        Text("Bing").tag("Bing")
                        Text("DuckDuckGo").tag("DuckDuckGo")
                    }
                }
                Section("Voice Settings") {
                    tuningSlider(label: "Pitch", value: $manager.config.voicePitch)
                    tuningSlider(label: "Speed", value: $manager.config.voiceSpeed)
                }
                Section("Behavior Toggles") {
                    Toggle("Agent Mode", isOn: $manager.agentModeEnabled)
                    Toggle("Continuous Training", isOn: $manager.config.isTrainingEnabled)
                    Toggle("Web Search", isOn: $manager.config.webSearchEnabled)
                    Toggle("Memory Enabled", isOn: $manager.config.memoryEnabled)
                    Toggle("MCP Tools Enabled", isOn: $manager.config.mcpToolsEnabled)
                    Toggle("Use Emojis", isOn: $manager.config.useEmoji)
                    Toggle("Use Markdown", isOn: $manager.config.useMarkdown)
                    Toggle("Include Sources", isOn: $manager.config.includeSources)
                    Toggle("Auto Correct", isOn: $manager.config.autoCorrect)
                    Toggle("Show Thinking", isOn: $manager.config.showThinking)
                    Toggle("Summarize Context", isOn: $manager.config.summarizeContext)
                    Toggle("Enable Images", isOn: $manager.config.enableImages)
                    Toggle("Enable Audio", isOn: $manager.config.enableAudio)
                    Toggle("Strict Compliance", isOn: $manager.config.strictCompliance)
                    Toggle("Model Fallback", isOn: $manager.config.modelFallback)
                    Toggle("Developer Mode", isOn: $manager.config.developerMode)
                }
                Section("MCP Servers") {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingFullScreenMCP = true
                        }
                    } label: {
                        HStack {
                            Text("Connected Servers")
                            Spacer()
                            Text("\(MCPManager.shared.servers.count)").foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Danger Zone") {
                    Button("Reset Persona", role: .destructive) {
                        manager.config = PersonaConfig(name: "Expert Assistant", instructions: "You are an expert AI Persona.", baseModel: "gpt-4", workspaceScope: ["All"])
                        manager.saveConfig()
                    }
                    Button("Clear Chat History", role: .destructive) { manager.clearHistory(); dismiss() }
                }
                Section { Button(action: onExport) { Label("Export Chat", systemImage: "square.and.arrow.up") } }
            }
            .navigationTitle("Tuning")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { manager.saveConfig(); dismiss() } } }
        }
    }

    private func tuningSlider(label: String, value: Binding<Double>) -> some View {
        VStack {
            HStack { Text(label); Spacer(); Text(String(format: "%.1f", value.wrappedValue)) }
            Slider(value: value, in: 0...1)
        }
    }
}

// MARK: - Modal Content

private struct PersonaHomeModalContent: View {
    let modal: PersonaHomeView.PersonaHomeModal
    @ObservedObject var manager: PersonaManager
    let onPromptSelection: (String) -> Void
    let onThreadSelection: (PersonaChatThread) -> Void
    @Binding var activeModal: PersonaHomeView.PersonaHomeModal?
    @Binding var showingFullScreenMCP: Bool
    @Binding var query: String
    let onVoiceFinished: () -> Void

    var body: some View {
        Group {
            switch modal {
            case .settings: TuningSheetView(manager: manager, onExport: { activeModal = .exportOptions }, showingFullScreenMCP: $showingFullScreenMCP)
            case .discovery: PromptDiscoveryView(onSelect: onPromptSelection).presentationDetents([.medium])
            case .chats: PersonaChatHistorySheet(threads: $manager.chatThreads, onContinue: onThreadSelection)
            case .actions: PersonaAgentActionGalleryView().presentationDetents([.medium, .large])
            case .voice: PersonaUserSpeak(query: $query, onFinished: onVoiceFinished).presentationDetents([.medium])
            case .exportOptions: PersonaExportOptionsView(messages: manager.chatHistory, persona: manager.config, agentMode: manager.agentModeEnabled) { d, f in activeModal = .shareSheet(data: d, filename: f) }
            case .shareSheet(let d, let f): ShareSheet(activityItems: [writeTemp(d, f)])
            }
        }
    }
    private func writeTemp(_ d: Data, _ f: String) -> URL {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent(f)
        try? d.write(to: u); return u
    }
}

// MARK: - Re-integrated Components from Original

private struct PersonaHomeToolbar: ToolbarContent {
    let onShowTuning: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onShowTuning) { Image(systemName: "slider.horizontal.3") }
        }
    }
}

private struct PersonaChatBubble: View {
    let message: PersonaMessage
    private var isUser: Bool { message.role == "user" }
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Group {
                if isUser {
                    Text(message.content).padding(14).background(Color.blue.opacity(0.8)).foregroundStyle(.white)
                } else {
                    SDKMarkdownView(text: message.content).padding(14).background(Color.primary.opacity(0.05)).foregroundStyle(.primary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            if !isUser { Spacer() }
        }.padding(.horizontal)
    }
}

private struct PersonaEmptyStateView: View {
    let onDiscoverPrompts: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles").font(.system(size: 60)).foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)).padding(.top, 100)
            Text("Your Workspace Intelligence").font(.title2.bold())
            Button(action: onDiscoverPrompts) { Label("Discover Prompts", systemImage: "lightbulb.fill").padding().background(Color.accentColor.opacity(0.1), in: Capsule()) }
        }.frame(maxWidth: .infinity)
    }
}

struct PromptDiscoveryView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (String) -> Void
    let prompts = ["Summarize my meetings", "Draft email to team", "Show priorities"]
    var body: some View {
        NavigationStack {
            List(prompts, id: \.self) { p in Button(p) { onSelect(p); dismiss() } }.navigationTitle("Discover")
        }
    }
}

struct PersonaChatHistorySheet: View {
    @Binding var threads: [PersonaChatThread]
    let onContinue: (PersonaChatThread) -> Void
    var body: some View {
        NavigationStack {
            List(threads) { t in Button(t.title) { onContinue(t) } }.navigationTitle("Chats")
        }
    }
}
struct ThinkingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.55)
                    .opacity(isAnimating ? 1.0 : 0.45)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.18),
                        value: isAnimating
                    )
            }
            Text("Persona is thinking…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .onAppear { isAnimating = true }
    }
}

struct PersonaActionConfirmationCard: View {
    let preview: PersonaAgentFramework.PersonaActionPreview
    let onConfirm: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Confirm Agent Action")
                    .font(.headline)
                Spacer()
            }

            Text(preview.intentDescription)
                .font(.subheadline)

            if !preview.parameterSummary.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(preview.parameterSummary.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text(key)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(value)
                                .font(.caption)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }

            if let warning = preview.warningMessage, !warning.isEmpty {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(role: .cancel) { onConfirm(false) } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) { onConfirm(true) } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }
}

struct PersonaAgentActionGalleryView: View {
    private let actionGroups: [(title: String, icon: String, actions: [String])] = [
        ("Mail", "envelope.fill", ["Send email", "Draft email", "Reply to email", "Forward email"]),
        ("Notes", "note.text", ["Create note", "Edit note", "Search notes", "Delete note"]),
        ("Calendar & Tasks", "calendar.badge.clock", ["Create event", "Edit event", "Create task", "Complete task"])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(actionGroups, id: \.title) { group in
                    Section {
                        ForEach(group.actions, id: \.self) { action in
                            Label(action, systemImage: group.icon)
                        }
                    } header: {
                        Text(group.title)
                    }
                }
            }
            .navigationTitle("Agent Actions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PersonaExportOptionsView: View {
    let messages: [PersonaMessage]
    let persona: PersonaConfig
    let agentMode: Bool
    let onExport: (Data, String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Formats") {
                    Button {
                        exportJSON()
                    } label: {
                        Label("Export JSON", systemImage: "curlybraces")
                    }

                    Button {
                        exportPlainText()
                    } label: {
                        Label("Export Transcript", systemImage: "doc.plaintext")
                    }
                }
            }
            .navigationTitle("Export Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func exportJSON() {
        let data = (try? PersonaChatExporter.export(
            messages: messages,
            actions: [],
            persona: persona,
            agentMode: agentMode,
            conversationID: UUID()
        )) ?? Data()
        onExport(data, "persona-chat.json")
    }

    private func exportPlainText() {
        let transcript = messages.map { message in
            "[\(message.timestamp.formatted(date: .abbreviated, time: .shortened))] \(message.role.capitalized): \(message.content)"
        }.joined(separator: "\n\n")
        onExport(Data(transcript.utf8), "persona-chat.txt")
    }
}
