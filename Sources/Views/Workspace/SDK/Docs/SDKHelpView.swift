import SwiftUI

struct SDKHelpView: View {
    @State private var query = ""
    @State private var conversation: [HelpMessage] = []
    @State private var isLoading = false
    @State private var selectedTopic: QuickTopic?
    @State private var showingTopicPicker = false

    struct HelpMessage: Identifiable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp: Date

        enum Role: String { case user, assistant }
    }

    enum QuickTopic: String, CaseIterable, Identifiable {
        case modules = "SDK Modules"
        case plugins = "Plugin System"
        case connectors = "Connectors"
        case dependencies = "Dependencies"
        case security = "Security & Permissions"
        case events = "Event Bus"
        case data = "Data Store"
        case troubleshoot = "Troubleshooting"

        var id: String { rawValue }

        var prompt: String {
            switch self {
            case .modules: return "Explain how SDK modules work, including registration, activation, dependency resolution, and feature exposure."
            case .plugins: return "Explain the plugin lifecycle system, including phases (loading, active, paused, updating), capability injection, and permission management."
            case .connectors: return "Explain how connectors work, including authentication methods, runtime binding with SDK modules, background sync, and live data streaming."
            case .dependencies: return "Explain SDK dependency management, including the dependency graph, conflict resolution, topological sorting, and library version resolution."
            case .security: return "Explain the SDK security model, including permission scopes, policy enforcement, rate limiting, audit logging, and sandbox execution."
            case .events: return "Explain the SDK event bus system, including channels, subscriptions, event history, persistence, and bridging with legacy systems."
            case .data: return "Explain the SDK data store, including the SDKModel protocol, offline-first persistence, batch operations, indexing, and collection management."
            case .troubleshoot: return "What are common SDK issues and how do I troubleshoot them? Cover module registration failures, plugin errors, connector auth issues, and build pipeline problems."
            }
        }

        var icon: String {
            switch self {
            case .modules: return "cpu"
            case .plugins: return "puzzlepiece.extension"
            case .connectors: return "link"
            case .dependencies: return "point.3.connected.trianglepath.dotted"
            case .security: return "lock.shield"
            case .events: return "antenna.radiowaves.left.and.right"
            case .data: return "database"
            case .troubleshoot: return "wrench.and.screwdriver"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if conversation.isEmpty {
                emptyState
            } else {
                conversationList
            }
            inputBar
        }
        .navigationTitle("SDK Help")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        conversation.removeAll()
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                    }
                    Button {
                        showingTopicPicker = true
                    } label: {
                        Label("Quick Topics", systemImage: "list.bullet")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingTopicPicker) {
            NavigationStack {
                List {
                    ForEach(QuickTopic.allCases) { topic in
                        Button {
                            selectedTopic = topic
                            showingTopicPicker = false
                            submitQuery(topic.prompt)
                        } label: {
                            Label(topic.rawValue, systemImage: topic.icon)
                        }
                    }
                }
                .navigationTitle("Quick Topics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingTopicPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor.opacity(0.6))
                    Text("SDK Help Assistant")
                        .font(.title3.bold())
                    Text("Ask about modules, plugins, connectors, dependencies, or any SDK feature.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(QuickTopic.allCases) { topic in
                        Button {
                            submitQuery(topic.prompt)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: topic.icon)
                                    .font(.title3)
                                Text(topic.rawValue)
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 40)
        }
    }

    private var conversationList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation) { message in
                        HStack(alignment: .top, spacing: 8) {
                            if message.role == .assistant {
                                Image(systemName: "cpu")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.top, 4)
                            }
                            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                                if message.role == .assistant {
                                    SDKMarkdownView(text: message.content)
                                        .padding(10)
                                        .background(
                                            Color.primary.opacity(0.04),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                } else {
                                    Text(message.content)
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(
                                            Color.accentColor.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                }
                                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 9)).foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                        }
                        .id(message.id)
                    }

                    if isLoading {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text("Thinking...").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(16)
            }
            .onChange(of: conversation.count) { _, _ in
                if let last = conversation.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about the SDK...", text: $query, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)

            Button(action: { submitQuery(query) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(query.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.accentColor)
            }
            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func submitQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        conversation.append(HelpMessage(role: .user, content: trimmed, timestamp: Date()))
        query = ""
        isLoading = true

        Task {
            do {
                let contextDocument = SDKAIContextProvider.loadContext()
                let systemPrompt = SDKAIContextProvider.helpSystemPrompt(context: contextDocument)
                let response = try await AIService.shared.processText(
                    prompt: trimmed,
                    systemPrompt: systemPrompt
                )
                await MainActor.run {
                    conversation.append(HelpMessage(role: .assistant, content: response, timestamp: Date()))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    conversation.append(HelpMessage(
                        role: .assistant,
                        content: "I couldn't process that request right now. Error: \(error.localizedDescription)",
                        timestamp: Date()
                    ))
                    isLoading = false
                }
            }
        }
    }
}
