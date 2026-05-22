import SwiftUI

struct SDKHelpView: View {
    @State private var query = ""
    @State private var conversation: [HelpMessage] = []
    @State private var isLoading = false
    @State private var selectedTopic: QuickTopic?
    @State private var showingTopicPicker = false
    @State private var activeTask: Task<Void, Never>?
    @State private var selectedCategory: TopicCategory = .all

    struct HelpMessage: Identifiable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp: Date

        enum Role: String { case user, assistant }
    }

    enum TopicCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case core = "Core"
        case integration = "Integration"
        case advanced = "Advanced"

        var id: String { rawValue }
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

        var category: TopicCategory {
            switch self {
            case .modules, .plugins, .data: return .core
            case .connectors, .dependencies: return .integration
            case .security, .events, .troubleshoot: return .advanced
            }
        }

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

        var gradient: [Color] {
            switch self {
            case .modules: return [.blue, .cyan]
            case .plugins: return [.purple, .indigo]
            case .connectors: return [.green, .mint]
            case .dependencies: return [.orange, .yellow]
            case .security: return [.red, .pink]
            case .events: return [.teal, .blue]
            case .data: return [.indigo, .purple]
            case .troubleshoot: return [.orange, .red]
            }
        }
    }

    private var filteredTopics: [QuickTopic] {
        if selectedCategory == .all { return QuickTopic.allCases }
        return QuickTopic.allCases.filter { $0.category == selectedCategory }
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("SDK Help")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        withAnimation { conversation.removeAll() }
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                    }
                    Button {
                        showingTopicPicker = true
                    } label: {
                        Label("Quick Topics", systemImage: "sparkles.rectangle.stack")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
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
        .onDisappear { activeTask?.cancel() }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "questionmark.bubble.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    Text("SDK Help Assistant")
                        .font(.title2.bold())
                    Text("Ask about modules, plugins, connectors, dependencies, or any SDK feature.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TopicCategory.allCases) { cat in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = cat }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        selectedCategory == cat
                                            ? Color.accentColor
                                            : Color(.tertiarySystemBackground),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedCategory == cat ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredTopics) { topic in
                        Button {
                            submitQuery(topic.prompt)
                        } label: {
                            VStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: topic.gradient.map { $0.opacity(0.15) },
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    Image(systemName: topic.icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: topic.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                Text(topic.rawValue)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: selectedCategory)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
    }

    private var conversationList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(conversation) { message in
                        HStack(alignment: .top, spacing: 10) {
                            if message.role == .assistant {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.12))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "cpu")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.accentColor)
                                }
                                .padding(.top, 2)
                            }
                            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                                if message.role == .assistant {
                                    SDKMarkdownView(text: message.content)
                                        .padding(12)
                                        .background(
                                            Color(.secondarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                } else {
                                    Text(message.content)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(
                                            LinearGradient(
                                                colors: [.accentColor.opacity(0.15), .accentColor.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.accentColor)
                            Text("Thinking...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                    }
                }
                .padding(16)
            }
            .onChange(of: conversation.count) { _, _ in
                guard let last = conversation.last else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about the SDK...", text: $query, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )

            Button(action: { submitQuery(query) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(query.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.accentColor)
            }
            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func submitQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        activeTask?.cancel()
        conversation.append(HelpMessage(role: .user, content: trimmed, timestamp: Date()))
        query = ""
        isLoading = true

        activeTask = Task {
            do {
                let contextDocument = try await Task.detached(priority: .userInitiated) {
                    SDKAIContextProvider.loadContext()
                }.value
                let systemPrompt = SDKAIContextProvider.helpSystemPrompt(context: contextDocument)
                try Task.checkCancellation()
                let response = try await AIService.shared.processText(
                    prompt: trimmed,
                    systemPrompt: systemPrompt
                )
                try Task.checkCancellation()
                await MainActor.run {
                    conversation.append(HelpMessage(role: .assistant, content: response, timestamp: Date()))
                    isLoading = false
                }
            } catch is CancellationError {
                await MainActor.run { isLoading = false }
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
