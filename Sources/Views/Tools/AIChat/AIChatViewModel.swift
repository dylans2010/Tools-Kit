import Foundation
import SwiftUI

final class AIChatViewModel: ObservableObject, @unchecked Sendable {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var apiKey: String = ""
    @Published var isApiKeySaved: Bool = false
    @Published var pendingAttachments: [ChatAttachment] = []
    @Published var settingsManager = AIChatSettingsManager.shared
    @Published var memoryStore = AIChatMemoryStore.shared
    @Published var keyValidationState: KeyValidationState = .unknown

    private let registry = AIProviderRegistry.shared
    private let keyManager = APIKeyManager.shared
    @MainActor private let featureCheck = AIFeatureCheck.shared
    @MainActor private let modelCatalog = AIModelCatalog.shared
    private let historyKey = "ai_chat_history"

    enum KeyValidationState {
        case unknown, validating, valid, invalid
    }

    var currentProvider: (any AIProvider)? {
        registry.provider(for: settingsManager.settings.selectedProviderID)
    }

    init() {
        let providerID = settingsManager.settings.selectedProviderID
        if let savedKey = keyManager.getKey(for: providerID) {
            self.apiKey = savedKey
            self.isApiKeySaved = true
        }
        loadHistory()
        Task { await refreshModels(force: false) }
    }

    // MARK: - Provider / Key Management

    func onProviderChanged() {
        let providerID = settingsManager.settings.selectedProviderID
        if let savedKey = keyManager.getKey(for: providerID) {
            apiKey = savedKey
            isApiKeySaved = true
            keyValidationState = .unknown
        } else {
            apiKey = ""
            isApiKeySaved = false
            keyValidationState = .unknown
        }
        Task { await refreshModels(force: true) }
    }

    func saveKey() {
        let providerID = settingsManager.settings.selectedProviderID
        guard keyManager.saveKey(apiKey, for: providerID) else { return }
        isApiKeySaved = true
        validateCurrentKey()
        Task { await refreshModels(force: true) }
    }

    func deleteKey() {
        let providerID = settingsManager.settings.selectedProviderID
        keyManager.deleteKey(for: providerID)
        apiKey = ""
        isApiKeySaved = false
        keyValidationState = .unknown
        settingsManager.settings.modelID = ""
    }

    func validateCurrentKey() {
        guard let provider = currentProvider,
              let key = keyManager.getKey(for: provider.id) else {
            keyValidationState = .unknown
            return
        }
        keyValidationState = .validating
        Task {
            do {
                let valid = try await provider.validateAPIKey(key)
                await MainActor.run {
                    self.keyValidationState = valid ? .valid : .invalid
                }
            } catch {
                await MainActor.run {
                    self.keyValidationState = .invalid
                }
            }
        }
    }

    // MARK: - Attachments

    func addAttachment(_ attachment: ChatAttachment) {
        pendingAttachments.append(attachment)
    }

    func removeAttachment(at index: Int) {
        guard index < pendingAttachments.count else { return }
        pendingAttachments.remove(at: index)
    }

    // MARK: - Vision Check

    func currentModelSupportsVision() -> Bool {
        let model = settingsManager.settings.modelID
        return currentProvider?.supportsVision(model: model) ?? false
    }

    @MainActor
    func availableModels() -> [AIModel] {
        modelCatalog.models(for: settingsManager.settings.selectedProviderID)
    }

    @MainActor
    func isLoadingModels() -> Bool {
        modelCatalog.loadingProviders.contains(settingsManager.settings.selectedProviderID)
    }

    @MainActor
    func refreshModels(force: Bool) async {
        let providerID = settingsManager.settings.selectedProviderID
        await modelCatalog.loadModels(for: providerID, force: force)
        let models = await MainActor.run { modelCatalog.models(for: providerID) }
        await MainActor.run {
            if !models.contains(where: { $0.id == self.settingsManager.settings.modelID }) {
                self.settingsManager.settings.modelID = models.first?.id ?? ""
            }
        }
    }

    // MARK: - Messaging

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
        guard let provider = currentProvider else {
            error = "No AI provider selected."
            return
        }
        let providerID = settingsManager.settings.selectedProviderID

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
                let authorization = try await featureCheck.authorizeRequest(providerID: providerID)
                let key = authorization.apiKey

                let response: String
                if !attachmentsToSend.isEmpty {
                    guard provider.supportsVision(model: model) else {
                        await MainActor.run {
                            self.error = "The selected model does not support vision/file attachments. Please choose a vision-capable model in settings."
                            self.isLoading = false
                            self.inputText = currentInput
                            self.pendingAttachments = attachmentsToSend
                        }
                        return
                    }
                    response = try await provider.sendWithAttachments(
                        messages: allMessages,
                        attachments: attachmentsToSend,
                        model: model,
                        apiKey: key
                    )
                } else {
                    response = try await provider.send(messages: allMessages, model: model, apiKey: key)
                }

                await MainActor.run {
                    self.messages.append(ChatMessage(role: "assistant", content: response))
                    self.isLoading = false
                    self.persistHistoryIfEnabled()
                }
            } catch {
                await MainActor.run {
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
