import SwiftUI

@MainActor
final class OpenClawChatViewModel: ObservableObject {
    @Published var inputText: String = ""
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
