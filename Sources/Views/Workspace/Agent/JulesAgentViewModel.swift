import Foundation

@MainActor
final class JulesAgentViewModel: AgentViewModelProtocol {
    @Published var messages: [SystemAgentMessage] = []
    @Published var state: SystemAgentState = .idle
    @Published var inputText: String = ""

    var isThinking: Bool {
        switch state {
        case .thinking, .executingTool:
            return true
        default:
            return false
        }
    }

    private let sessionManager: AgentSessionManager

    init(sessionManager: AgentSessionManager = .shared) {
        self.sessionManager = sessionManager
    }

    func submit() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        messages.append(SystemAgentMessage(role: .user, content: prompt))
        inputText = ""
        state = .thinking

        do {
            let session = try await sessionManager.startSession(prompt: prompt, owner: "local", repo: "workspace")
            state = .responding
            messages.append(SystemAgentMessage(role: .assistant, content: "Started Jules session: \(session.id)"))
            state = .idle
        } catch {
            state = .failed(error)
            messages.append(SystemAgentMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
        }
    }

    func retryLastSubmission() async {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }
        inputText = lastUserMessage.content
        await submit()
    }

    func reset() {
        messages = []
        state = .idle
        inputText = ""
    }
}
