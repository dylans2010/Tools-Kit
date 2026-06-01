import SwiftUI
import Aurora

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var activeModal: PersonaHomeModal?
    @State private var chatThreads: [PersonaChatThread] = []
    @State private var activeThreadID: UUID?
    @State private var agentModeEnabled = false
    @State private var pendingAction: PersonaAgentFramework.PersonaActionPreview?
    @State private var pendingIntent: PersonaAgentFramework.PersonaIntent?
    @State private var clarificationMissingField: String?

    enum PersonaHomeModal: Identifiable {
        case chats, settings, discovery, actions, exportOptions
        case shareSheet(data: Data, filename: String)
        var id: String {
            switch self {
            case .chats: return "chats"
            case .settings: return "settings"
            case .discovery: return "discovery"
            case .actions: return "actions"
            case .exportOptions: return "exportOptions"
            case .shareSheet: return "shareSheet"
            }
        }
    }

    var body: some View {
        ZStack {
            PersonaHomeNavigationContent(
                chatHistory: manager.chatHistory,
                isThinking: manager.isThinking,
                agentMode: agentModeEnabled,
                query: $query,
                pendingAction: pendingAction,
                onSend: sendMessage,
                onOpenDiscovery: { activeModal = .discovery },
                onOpenChats: { activeModal = .chats },
                onOpenActions: { activeModal = .actions },
                onConfirm: handleConfirmation(_:)
            )
        }
        .aiAnimationLoading(manager.isThinking)
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PersonaHomeToolbar(
                agentMode: $agentModeEnabled,
                onShowWelcome: { activeModal = .discovery },
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
                activeModal: $activeModal
            )
        }
    }

    private func sendMessage() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        query = ""
        manager.agentModeEnabled = agentModeEnabled
        if agentModeEnabled {
            Task { await processAgentMessage(trimmed) }
        } else {
            Task { await manager.queryPersonaSafely(query: trimmed) }
        }
    }

    // Existing Agent Logic Preserved
    private func processAgentMessage(_ input: String) async {
        let history = manager.chatHistory
        let engine = PersonaAgentFramework.PersonaIntentEngine()
        let dispatcher = PersonaAgentFramework.PersonaActionDispatcher()
        let contacts = AccountManager.shared.accounts.map { PersonaAgentFramework.PersonaContact(name: $0.displayName, email: $0.emailAddress) }
        let context = PersonaAgentFramework.PersonaWorkspaceContext(contacts: contacts, lastAccessedNote: nil, activeDraft: nil, recentEmails: [])

        manager.chatHistory.append(PersonaMessage(role: "user", content: input))
        manager.isThinking = true

        var finalIntent: PersonaAgentFramework.PersonaIntent
        if let missing = clarificationMissingField, var intent = pendingIntent {
            switch intent {
            case .sendEmail(var p): if missing == "recipients" { p.recipients = [input] }; intent = .sendEmail(parameters: p)
            case .createNote(var p): if missing == "body" { p.body = input }; intent = .createNote(parameters: p)
            default: break
            }
            finalIntent = intent
            clarificationMissingField = nil
            pendingIntent = nil
        } else {
            finalIntent = await engine.classify(input: input, conversationHistory: history, workspaceContext: context)
        }

        if case .compound(let steps) = finalIntent {
            for step in steps {
                let res = await dispatcher.dispatch(step, in: context)
                await handleActionResult(res, intent: step)
                if case .failed = res { break }
            }
        } else {
            let res = await dispatcher.dispatch(finalIntent, in: context)
            await handleActionResult(res, intent: finalIntent)
        }
        manager.isThinking = false
    }

    private func handleActionResult(_ result: PersonaAgentFramework.PersonaActionResult, intent: PersonaAgentFramework.PersonaIntent) async {
        switch result {
        case .success(let s, _): manager.chatHistory.append(PersonaMessage(role: "assistant", content: s))
        case .requiresConfirmation(let p): pendingAction = p; pendingIntent = intent
        case .failed(let e): manager.chatHistory.append(PersonaMessage(role: "assistant", content: "Error: \(e.localizedDescription)"))
        case .clarificationNeeded(let q, let f):
            manager.chatHistory.append(PersonaMessage(role: "assistant", content: q))
            clarificationMissingField = f
            pendingIntent = intent
        }
    }

    private func handleConfirmation(_ confirmed: Bool) {
        guard confirmed, let intent = pendingIntent else { pendingAction = nil; pendingIntent = nil; return }
        Task {
            let dispatcher = PersonaAgentFramework.PersonaActionDispatcher()
            let contacts = AccountManager.shared.accounts.map { PersonaAgentFramework.PersonaContact(name: $0.displayName, email: $0.emailAddress) }
            let context = PersonaAgentFramework.PersonaWorkspaceContext(contacts: contacts, lastAccessedNote: nil, activeDraft: nil, recentEmails: [])
            let result: PersonaAgentFramework.PersonaActionResult
            switch intent {
            case .deleteNote(let id): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteWorkspaceItem(id: id, type: .note)))
            case .deleteEvent(let p): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteEvent(parameters: p)))
            case .deleteTask(let id): result = .from(try! await PersonaAgentFramework.shared.execute(.deleteTask(id: id)))
            default: result = .failed(error: .serviceUnavailable("Not implemented"))
            }
            pendingAction = nil
            pendingIntent = nil
            await handleActionResult(result, intent: intent)
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
    let onConfirm: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AuroraGlow(.subtle).palette(.appleIntelligence).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
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
                    .onChange(of: chatHistory.count) { _, _ in withAnimation { if let id = chatHistory.last?.id { proxy.scrollTo(id, anchor: .bottom) } } }
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
                    Button(action: {}) { Image(systemName: "mic.fill").font(.title3).foregroundStyle(.secondary) }
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Persona Identity") {
                    TextField("Name", text: $manager.config.name)
                    TextEditor(text: $manager.config.instructions).frame(height: 80)
                }
                Section("Personality Sliders") {
                    tuningSlider(label: "Creativity", value: $manager.config.creativity)
                    tuningSlider(label: "Formality", value: $manager.config.formality)
                    tuningSlider(label: "Humor", value: $manager.config.humor)
                }
                Section("Behavior Toggles") {
                    Toggle("Web Search", isOn: $manager.config.webSearchEnabled)
                    Toggle("Memory Enabled", isOn: $manager.config.memoryEnabled)
                    Toggle("MCP Tools Enabled", isOn: $manager.config.mcpToolsEnabled)
                }
                Section("MCP Servers") {
                    NavigationLink(destination: MCPMainView()) {
                        HStack { Text("Connected Servers"); Spacer(); Text("\(MCPManager.shared.servers.count)").foregroundStyle(.secondary) }
                    }
                }
                Section("Danger Zone") {
                    Button("Reset Persona", role: .destructive) { manager.config = PersonaConfig(name: "Expert Assistant", instructions: "You are an expert AI Persona.", baseModel: "gpt-4", workspaceScope: ["All"]); manager.saveConfig() }
                    Button("Clear Chat History", role: .destructive) { manager.clearHistory(); dismiss() }
                }
                Section { Button(action: onExport) { Label("Export Chat", systemImage: "square.and.arrow.up") } }
            }
            .navigationTitle("Tuning").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { manager.saveConfig(); dismiss() } } }
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

    var body: some View {
        Group {
            switch modal {
            case .settings: TuningSheetView(manager: manager, onExport: { activeModal = .exportOptions })
            case .discovery: PromptDiscoveryView(onSelect: onPromptSelection).presentationDetents([.medium])
            case .chats: PersonaChatHistorySheet(threads: $manager.chatThreads, onContinue: onThreadSelection)
            case .actions: PersonaAgentActionGalleryView().presentationDetents([.medium, .large])
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
    @Binding var agentMode: Bool
    let onShowWelcome: () -> Void
    let onShowTuning: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Toggle(isOn: $agentMode) { Label("Agent", systemImage: "bolt.shield") }.toggleStyle(.button).tint(.orange)
                Button(action: onShowTuning) { Image(systemName: "slider.horizontal.3") }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                Button(action: onShowWelcome) { Image(systemName: "info.circle") }
                NavigationLink(destination: MCPMainView()) { Image(systemName: "network").foregroundStyle(.blue) }
            }
        }
    }
}

private struct PersonaChatBubble: View {
    let message: PersonaMessage
    private var isUser: Bool { message.role == "user" }
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(message.content).padding(14).background(isUser ? Color.blue.opacity(0.8) : Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20)).foregroundStyle(isUser ? .white : .primary)
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

// Stub for Missing View from Original
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
