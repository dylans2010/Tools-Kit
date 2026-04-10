import Foundation
import SwiftUI

class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var apiKey: String = ""
    @Published var isApiKeySaved: Bool = false
    @Published var pendingAttachments: [ChatAttachment] = []
    @Published var settingsManager = AIChatSettingsManager.shared
    @Published var memoryStore = AIChatMemoryStore.shared

    private let aiService = OpenRouterService()
    private let keyManager = APIKeyManager.shared
    private let historyKey = "ai_chat_history"

    init() {
        if let savedKey = keyManager.getKey() {
            self.apiKey = savedKey
            self.isApiKeySaved = true
        }
        loadHistory()
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

    func addAttachment(_ attachment: ChatAttachment) {
        pendingAttachments.append(attachment)
    }

    func removeAttachment(at index: Int) {
        guard index < pendingAttachments.count else { return }
        pendingAttachments.remove(at: index)
    }

    private func buildSystemPrompt() -> String? {
        let s = settingsManager.settings
        var parts: [String] = []

        if !s.systemPrompt.isEmpty {
            parts.append(s.systemPrompt)
        }

        if s.useCustomPersonality && !s.personalityName.isEmpty {
            parts.append("Your name is \(s.personalityName).")
        }

        if s.useCustomPersonality && !s.personalityTraits.isEmpty {
            parts.append("Personality traits: \(s.personalityTraits.joined(separator: ", ")).")
        }

        if !s.expertiseAreas.isEmpty {
            parts.append("Areas of expertise: \(s.expertiseAreas.joined(separator: ", ")).")
        }

        if !s.knowledgeContext.isEmpty {
            parts.append(s.knowledgeContext)
        }
        if s.memoryEnabled {
            let memory = memoryStore.contextSnippet()
            if !memory.isEmpty { parts.append(memory) }
        }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        if settingsManager.settings.memoryEnabled {
            memoryStore.ingestUserMessage(inputText, sensitivity: settingsManager.settings.memorySensitivity)
        }
        let currentInput = inputText
        let attachmentsToSend = pendingAttachments
        inputText = ""
        pendingAttachments = []
        isLoading = true
        error = nil

        let model = settingsManager.settings.modelID

        var allMessages = messages
        if let systemPrompt = buildSystemPrompt() {
            let systemMessage = ChatMessage(role: "system", content: systemPrompt)
            allMessages.insert(systemMessage, at: 0)
        }

        Task {
            do {
                let response: String
                if !attachmentsToSend.isEmpty {
                    guard OpenRouterService.supportsVision(model: model) else {
                        DispatchQueue.main.async {
                            self.error = "The selected model does not support vision/file attachments. Please choose a vision-capable model in settings."
                            self.isLoading = false
                            self.inputText = currentInput
                            self.pendingAttachments = attachmentsToSend
                        }
                        return
                    }
                    response = try await aiService.sendMessageWithAttachments(
                        messages: allMessages,
                        attachments: attachmentsToSend,
                        model: model,
                        apiKey: apiKey
                    )
                } else {
                    response = try await aiService.sendMessage(messages: allMessages, apiKey: apiKey, model: model)
                }

                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(role: "assistant", content: response))
                    self.isLoading = false
                    self.persistHistoryIfEnabled()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Request failed: \(error.localizedDescription)"
                    if self.settingsManager.settings.logErrorsToConsole {
                        print("AIChat error: \(String(describing: error))")
                    }
                    self.isLoading = false
                    self.inputText = currentInput
                    self.pendingAttachments = attachmentsToSend
                }
            }
        }
    }

    func clearChat() {
        messages = []
        persistHistoryIfEnabled()
    }

    private func persistHistoryIfEnabled() {
        guard settingsManager.settings.saveChatHistory else {
            UserDefaults.standard.removeObject(forKey: historyKey)
            return
        }
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = decoded
    }
}
