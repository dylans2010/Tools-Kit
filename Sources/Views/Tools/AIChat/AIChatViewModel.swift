import Foundation
import SwiftUI

class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var apiKey: String = ""
    @Published var isApiKeySaved: Bool = false

    private let aiService = OpenRouterService()
    private let keyManager = APIKeyManager.shared

    init() {
        if let savedKey = keyManager.getKey() {
            self.apiKey = savedKey
            self.isApiKeySaved = true
        }
    }

    func saveKey() {
        if keyManager.saveKey(apiKey) {
            isApiKeySaved = true
        }
    }

    func deleteKey() {
        keyManager.deleteKey()
        apiKey = ""
        isApiKeySaved = false
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        let currentInput = inputText
        inputText = ""
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await aiService.sendMessage(messages: messages, apiKey: apiKey)
                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(role: "assistant", content: response))
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    self.inputText = currentInput
                }
            }
        }
    }

    func clearChat() {
        messages = []
    }
}
