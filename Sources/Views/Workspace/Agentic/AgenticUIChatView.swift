import SwiftUI

struct AgenticUIChatView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @State private var prompt: String = ""
    @State private var chatMessages: [ChatEntry] = []
    @FocusState private var isInputFocused: Bool

    struct ChatEntry: Identifiable {
        let id = UUID()
        let role: ChatRole
        let content: String
        let timestamp: Date

        enum ChatRole: String {
            case user
            case assistant
            case system
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if chatMessages.isEmpty && !sessionManager.isStreaming {
                emptyState
            } else {
                messageList
            }

            if sessionManager.isStreaming {
                streamingIndicator
            }

            inputBar
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Agentic Runtime")
                .font(.title2.weight(.semibold))

            Text("Ask anything about your workspace. The system will analyze your project structure, generate tools dynamically, and stream responses using Foundation Models.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let graph = orchestrator.workspaceGraph {
                VStack(spacing: 4) {
                    Text("\(graph.modules.count) modules analyzed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(graph.featureDomains.count) feature domains detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }

            suggestedPrompts

            Spacer()
        }
    }

    private var suggestedPrompts: some View {
        VStack(spacing: 8) {
            Text("Try asking:")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            ForEach(samplePrompts, id: \.self) { sample in
                Button {
                    prompt = sample
                    sendMessage()
                } label: {
                    Text(sample)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
    }

    private var samplePrompts: [String] {
        [
            "Analyze the workspace architecture",
            "What feature domains exist in the project?",
            "Show me the module dependency graph",
            "What capabilities are missing?"
        ]
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatMessages) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }

                    if sessionManager.isStreaming && !sessionManager.currentResponse.isEmpty {
                        streamingBubble
                    }
                }
                .padding()
            }
            .onChange(of: chatMessages.count) { _ in
                if let last = chatMessages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func chatBubble(for entry: ChatEntry) -> some View {
        HStack {
            if entry.role == .user { Spacer(minLength: 60) }

            VStack(alignment: entry.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if entry.role != .user {
                        Image(systemName: entry.role == .assistant ? "sparkles" : "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.role.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(entry.content)
                    .font(.body)
                    .padding(12)
                    .background(entry.role == .user ? Color.accentColor : Color(.systemGray6))
                    .foregroundStyle(entry.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if entry.role != .user { Spacer(minLength: 60) }
        }
    }

    private var streamingBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Assistant")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView()
                        .scaleEffect(0.6)
                }

                Text(sessionManager.currentResponse)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer(minLength: 60)
        }
    }

    // MARK: - Streaming Indicator

    private var streamingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text(streamingStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(sessionManager.tokens.count) tokens")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    private var streamingStatusText: String {
        switch orchestrator.state {
        case .checkingAvailability: return "Checking Foundation Models..."
        case .analyzingWorkspace: return "Analyzing workspace..."
        case .generatingTools: return "Generating tools..."
        case .streaming: return "Streaming response..."
        case .executingTool: return "Executing tools..."
        default: return "Processing..."
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your workspace...", text: $prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
            }
            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sessionManager.isStreaming)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userEntry = ChatEntry(role: .user, content: trimmed, timestamp: Date())
        chatMessages.append(userEntry)
        prompt = ""
        isInputFocused = false

        Task {
            await orchestrator.run(prompt: trimmed)

            if !orchestrator.finalResponse.isEmpty {
                let assistantEntry = ChatEntry(
                    role: .assistant,
                    content: orchestrator.finalResponse,
                    timestamp: Date()
                )
                chatMessages.append(assistantEntry)
            }
        }
    }
}
