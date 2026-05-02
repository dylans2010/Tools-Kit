import Foundation
import SwiftUI
import Combine

@MainActor
final class SystemAgentViewModel: AgentViewModelProtocol {
    @Published private(set) var messages: [SystemAgentMessage] = []
    @Published private(set) var state: SystemAgentState = .idle
    @Published var inputText: String = ""

    var isThinking: Bool {
        if case .thinking = state { return true }
        if case .executingTool = state { return true }
        return false
    }

    private let agent: SystemAgent
    private var cancellables = Set<AnyCancellable>()

    init(agent: SystemAgent) {
        self.agent = agent
        setupBindings()
    }

    private func setupBindings() {
        Task {
            for await history in await agent.historyStream() {
                await MainActor.run {
                    self.messages = history
                }
            }
        }

        Task {
            for await state in await agent.stateStream() {
                await MainActor.run {
                    self.state = state
                }
            }
        }
    }

    func submit() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        inputText = ""

        do {
            _ = try await agent.sendMessage(prompt)
        } catch {
            print("Failed to send message: \(error)")
        }
    }

    func retryLastSubmission() async {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }
        inputText = lastUserMessage.content
        await submit()
    }

    func reset() {
        Task {
            await agent.resetSession()
        }
    }
}
