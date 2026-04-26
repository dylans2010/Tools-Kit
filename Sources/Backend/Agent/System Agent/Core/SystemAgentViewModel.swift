import Foundation
import SwiftUI
import Combine

public final class SystemAgentViewModel: AgentViewModelProtocol {
    @Published public private(set) var messages: [SystemAgentMessage] = []
    @Published public private(set) var state: SystemAgentState = .idle

    public var isThinking: Bool {
        if case .thinking = state { return true }
        if case .executingTool = state { return true }
        return false
    }

    private let agent: SystemAgent
    private var cancellables = Set<AnyCancellable>()

    public init(agent: SystemAgent) {
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

    public func sendMessage(_ content: String) async {
        do {
            _ = try await agent.sendMessage(content)
        } catch {
            print("Failed to send message: \(error)")
        }
    }

    public func reset() {
        Task {
            await agent.resetSession()
        }
    }
}
