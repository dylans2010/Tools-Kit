import SwiftUI
import Aurora

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @StateObject private var agent = PersonaAgentFramework.shared
    @State private var query = ""
    @State private var isExpanded = false
    @Namespace private var animation

    private let navyBackground = Color(red: 10/255, green: 15/255, blue: 30/255)
    private let electricBlue = Color(red: 61/255, green: 142/255, blue: 255/255)

    var body: some View {
        ZStack(alignment: .bottom) {
            navyBackground
                .ignoresSafeArea()

            // Background Content (Timeline)
            PersonaChatTimelineView(
                chatHistory: manager.chatHistory,
                isThinking: manager.isThinking,
                onDiscoverPrompts: { },
                onNeedScroll: { _ in }
            )
            .padding(.bottom, isExpanded ? 400 : 100)

            // Agent command surface
            VStack {
                Spacer()
                agentSurface
            }
        }
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.clearHistory()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private var agentSurface: some View {
        VStack(spacing: 0) {
            if isExpanded {
                actionFeed
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                statusIndicator
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    }

                if !isExpanded {
                    Text(agent.currentPlan.last?.description ?? "No actions yet")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "status_text", in: animation)
                }

                TextField("", text: $query, prompt: Text("Command workspace...").foregroundColor(.secondary.opacity(0.5)))
                    .font(.system(.body, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)

                Button(action: runCommand) {
                    if manager.isThinking {
                        ProgressView()
                            .tint(electricBlue)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(electricBlue)
                    }
                }
                .disabled(query.isEmpty || manager.isThinking)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(isExpanded ? 24 : 30)
            .padding(isExpanded ? 16 : 8)
            .matchedGeometryEffect(id: "container", in: animation)
        }
        .background(isExpanded ? Color.black.opacity(0.4) : Color.clear)
        .ignoresSafeArea(edges: .bottom)
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Circle()
                .stroke(statusColor.opacity(0.5), lineWidth: 4)
                .frame(width: 14, height: 14)
                .scaleEffect(manager.isThinking ? 1.4 : 1.0)
                .opacity(manager.isThinking ? 0 : 1)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: manager.isThinking)
        }
    }

    private var actionFeed: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ACTIVITY FEED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Collapse") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isExpanded = false
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(electricBlue)
            }
            .padding(.horizontal)
            .padding(.top, 20)

            ScrollView {
                LazyVStack(spacing: 12) {
                    if agent.currentPlan.isEmpty {
                        Text("Ready for instructions.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 40)
                    } else {
                        ForEach(agent.currentPlan.reversed()) { step in
                            actionRow(step)
                        }
                    }
                }
                .padding()
            }
            .frame(height: 300)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, -12)
    }

    private func actionRow(_ step: PersonaAgentFramework.PersonaAgentPlanStep) -> some View {
        HStack(spacing: 12) {
            Image(systemName: stepIcon(step.status))
                .foregroundStyle(stepColor(step.status))
                .font(.system(size: 14))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white)

                Text(Date().formatted(date: .omitted, time: .standard))
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch agent.executionState {
        case .idle: return .blue
        case .thinking: return .orange
        case .acting: return .green
        case .error: return .red
        }
    }

    private func stepIcon(_ status: PersonaAgentFramework.PersonaAgentPlanStep.StepStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func stepColor(_ status: PersonaAgentFramework.PersonaAgentPlanStep.StepStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func runCommand() {
        let cmd = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        query = ""

        Task {
            await manager.queryPersonaSafely(query: cmd)
        }
    }
}

// Re-using simplified timeline for layout
private struct PersonaChatTimelineView: View {
    let chatHistory: [PersonaMessage]
    let isThinking: Bool
    let onDiscoverPrompts: () -> Void
    let onNeedScroll: (ScrollViewProxy) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if chatHistory.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .padding(.top, 100)
                            Text("Agent Intelligence").font(.title2.bold()).foregroundStyle(.white)
                        }
                    } else {
                        ForEach(chatHistory) { message in
                            chatBubble(message)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func chatBubble(_ message: PersonaMessage) -> some View {
        HStack {
            if message.role == "user" { Spacer() }
            Text(message.content)
                .padding()
                .background(message.role == "user" ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                .cornerRadius(16)
                .foregroundStyle(.white)
            if message.role != "user" { Spacer() }
        }
    }
}
