import Foundation
import Combine

struct OpenClawAgentMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

@MainActor
final class OpenClawAgentService: ObservableObject {
    @Published var messages: [OpenClawAgentMessage] = []
    @Published var isStreaming = false

    private var cancellables = Set<AnyCancellable>()
    private var currentRunID: String?

    init() {
        OpenClawMessageBus.shared.events
            .filter { $0.event == "agent.stream" }
            .sink { [weak self] event in
                self?.handleStreamEvent(event)
            }
            .store(in: &cancellables)
    }

    func sendMessage(_ text: String) async {
        let userMsg = OpenClawAgentMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)

        isStreaming = true
        let runID = UUID().uuidString
        currentRunID = runID

        let aiMsg = OpenClawAgentMessage(text: "", isUser: false, timestamp: Date())
        messages.append(aiMsg)

        do {
            let params: [String: AnyCodable] = [
                "prompt": AnyCodable(text),
                "run_id": AnyCodable(runID)
            ]
            _ = try await OpenClawService.shared.sendRPC("agent.run", params: params)
        } catch {
            updateLastAIMessage("Error: \(error.localizedDescription)")
            isStreaming = false
        }
    }

    private func handleStreamEvent(_ event: OpenClawEvent) {
        guard let payload = event.payload.value as? [String: Any],
              let token = payload["token"] as? String,
              let runID = payload["run_id"] as? String,
              runID == currentRunID else { return }

        DispatchQueue.main.async {
            self.appendTokenToLastMessage(token)
            if let isFinal = payload["is_final"] as? Bool, isFinal {
                self.isStreaming = false
            }
        }
    }

    private func appendTokenToLastMessage(_ token: String) {
        guard let lastIndex = messages.lastIndex(where: { !$0.isUser }) else { return }
        let currentText = messages[lastIndex].text
        messages[lastIndex] = OpenClawAgentMessage(text: currentText + token, isUser: false, timestamp: messages[lastIndex].timestamp)
    }

    private func updateLastAIMessage(_ text: String) {
        guard let lastIndex = messages.lastIndex(where: { !$0.isUser }) else { return }
        messages[lastIndex] = OpenClawAgentMessage(text: text, isUser: false, timestamp: messages[lastIndex].timestamp)
    }
}
