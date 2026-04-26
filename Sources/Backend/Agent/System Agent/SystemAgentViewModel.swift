import Foundation

@MainActor
final class SystemAgentViewModel: AgentViewModelProtocol {
    @Published var messages: [SystemAgentMessage] = []
    @Published var state: SystemAgentState = .idle
    @Published var inputText: String = ""
    @Published var userFacingErrorMessage: String?

    private let agent: SystemAgent
    private var stateTask: Task<Void, Never>?

    init(aiService: AIService = .shared) {
        self.agent = SystemAgent(aiService: aiService)
        observeAgentState()
    }

    deinit {
        stateTask?.cancel()
    }

    func submit() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        print("[SystemAgentViewModel] submit started")
        inputText = ""
        userFacingErrorMessage = nil

        do {
            print("[SystemAgentViewModel] calling agent.sendMessage")
            _ = try await agent.sendMessage(trimmed)
            messages = await agent.history
            state = await agent.currentState
            print("[SystemAgentViewModel] submit succeeded")
        } catch {
            print("[SystemAgentViewModel] submit failed: \(error.localizedDescription)")
            state = .failed(error)
            userFacingErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            messages = await agent.history
            messages.append(SystemAgentMessage(role: .assistant, content: "Error: \(userFacingErrorMessage ?? "Unknown error")"))
        }
    }

    func reset() {
        Task {
            await agent.resetSession()
            await MainActor.run {
                self.messages = []
                self.state = .idle
                self.userFacingErrorMessage = nil
                self.inputText = ""
            }
        }
    }

    private func observeAgentState() {
        stateTask = Task { [weak self] in
            guard let self else { return }
            let stream = await agent.stateStream()
            for await newState in stream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
