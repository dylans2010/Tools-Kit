import SwiftUI
import Observation

@MainActor @Observable
final class OpenClawChatViewModel {
    var inputText: String = ""
    private let agentService = OpenClawAgentService()

    var messages: [OpenClawAgentMessage] { agentService.messages }
    var isStreaming: Bool { agentService.isStreaming }

    func send() {
        let text = inputText
        inputText = ""
        Task {
            await agentService.sendMessage(text)
        }
    }
}
