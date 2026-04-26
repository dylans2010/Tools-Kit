import Foundation

@MainActor
final class SystemAgentViewModel: AgentViewModelProtocol {
    @Published var messages: [SystemAgentMessage] = []
    @Published var state: SystemAgentState = .idle
    @Published var inputText: String = ""
    @Published var userFacingErrorMessage: String?

    private let agent: SystemAgent
    private var stateTask: Task<Void, Never>?
    private var historyTask: Task<Void, Never>?
    private var lastSubmittedInput: String?

    init(aiService: AIService = .shared) {
        self.agent = SystemAgent(aiService: aiService)
        observeAgentState()
    }

    deinit {
        stateTask?.cancel()
        historyTask?.cancel()
    }

    func submit() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lastSubmittedInput = trimmed
        inputText = ""
        userFacingErrorMessage = nil
        state = .thinking

        do {
            _ = try await agent.sendMessage(trimmed)
            state = .completed
        } catch {
            state = .failed(error)
            userFacingErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            messages.append(SystemAgentMessage(role: .failed(message: userFacingErrorMessage ?? "Unknown error"), content: "Error: \(userFacingErrorMessage ?? "Unknown error")"))
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

        historyTask = Task { [weak self] in
            guard let self else { return }
            let stream = await agent.historyStream()
            for await newHistory in stream {
                await MainActor.run {
                    self.messages = newHistory
                }
            }
        }
    }

    func retryLastSubmission() async {
        guard let lastSubmittedInput else { return }
        inputText = lastSubmittedInput
        await submit()
    }
}
