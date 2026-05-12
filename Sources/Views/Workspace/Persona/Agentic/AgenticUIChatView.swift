import SwiftUI
import FoundationModels

struct AgenticUIChatView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @State private var inputText = ""
    @State private var messages: [AgenticChatMessage] = []
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                streamingIndicator
                inputBar
            }
            .navigationTitle("Agentic Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isProcessing {
                        Button {
                            orchestrator.interrupt()
                            isProcessing = false
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        AgenticChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Streaming Indicator

    @ViewBuilder
    private var streamingIndicator: some View {
        if sessionManager.isStreaming {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Streaming...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(sessionManager.streamedTokens.count) tokens")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if !sessionManager.currentResponse.isEmpty {
                    Text(sessionManager.currentResponse)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }

        if orchestrator.executionState == .executingTool {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                if let toolName = AgenticExecutionTraceStore.shared.activeToolName {
                    Text("Executing: \(toolName)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .disabled(isProcessing)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = AgenticChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isProcessing = true

        Task {
            do {
                let response = try await orchestrator.execute(prompt: text)

                let assistantMessage = AgenticChatMessage(
                    role: .assistant,
                    content: response.message,
                    actions: response.actions,
                    confidence: response.confidenceScore
                )
                messages.append(assistantMessage)

                for (toolName, output) in orchestrator.toolOutputs {
                    let toolMessage = AgenticChatMessage(
                        role: .tool,
                        content: output.summary,
                        toolName: toolName,
                        generatedCode: output.generatedCode
                    )
                    messages.append(toolMessage)
                }
            } catch {
                let errorMessage = AgenticChatMessage(
                    role: .system,
                    content: "Error: \(error.localizedDescription)"
                )
                messages.append(errorMessage)
            }

            isProcessing = false
        }
    }
}

// MARK: - Chat Message Model

struct AgenticChatMessage: Identifiable, Sendable {
    let id = UUID()
    let timestamp = Date()
    let role: AgenticChatRole
    let content: String
    var actions: [AgenticModelAction] = []
    var confidence: Double = 0
    var toolName: String?
    var generatedCode: String?
}

enum AgenticChatRole: Sendable {
    case user, assistant, system, tool
}

// MARK: - Chat Bubble

private struct AgenticChatBubble: View {
    let message: AgenticChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: iconForRole)
                        .font(.caption)
                        .foregroundStyle(colorForRole)

                    Text(labelForRole)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if message.confidence > 0 {
                        Text("\(Int(message.confidence * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(backgroundForRole, in: RoundedRectangle(cornerRadius: 16))

                if let code = message.generatedCode {
                    DisclosureGroup("Generated Code") {
                        ScrollView(.horizontal) {
                            Text(code)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                        }
                        .frame(maxHeight: 200)
                        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .font(.caption)
                }

                if !message.actions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(message.actions.indices, id: \.self) { index in
                            let action = message.actions[index]
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape.fill")
                                    .font(.caption2)
                                Text(action.toolName)
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                }
            }

            if message.role != .user { Spacer() }
        }
    }

    private var iconForRole: String {
        switch message.role {
        case .user: return "person.fill"
        case .assistant: return "cpu"
        case .system: return "exclamationmark.triangle"
        case .tool: return "wrench.and.screwdriver"
        }
    }

    private var labelForRole: String {
        switch message.role {
        case .user: return "You"
        case .assistant: return "Agentic AI"
        case .system: return "System"
        case .tool: return message.toolName ?? "Tool"
        }
    }

    private var colorForRole: Color {
        switch message.role {
        case .user: return .blue
        case .assistant: return .purple
        case .system: return .red
        case .tool: return .orange
        }
    }

    private var backgroundForRole: some ShapeStyle {
        switch message.role {
        case .user: return .tint.opacity(0.15)
        case .assistant: return .fill.tertiary
        case .system: return .red.opacity(0.1)
        case .tool: return .orange.opacity(0.1)
        }
    }
}
