import Foundation

// MARK: - Local Models Provider

final class LocalModelsProvider: AIProvider {
    let id = "local_models"
    let name = "Local Models"
    let icon = "desktopcomputer"
    let apiKeyURL: URL? = nil
    let apiKeyPlaceholder = "Optional API Key"

    var models: [AIModel] = []

    private let settingsManager = AIChatSettingsManager.shared

    private var activeConfig: LocalModelConfig? {
        let settings = settingsManager.settings
        if let selectedID = settings.selectedLocalConfigID {
            return settings.localConfigs.first { $0.id == selectedID }
        }
        return settings.localConfigs.first
    }

    func supportsVision(model: String) -> Bool {
        let lowered = model.lowercased()
        return lowered.contains("vision") || lowered.contains("llava") || lowered.contains("vl") || lowered.contains("multimodal")
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        guard let config = activeConfig else {
            throw AIProviderError.networkError("No local configuration found. Please set up a local model in settings.")
        }

        let parameters = buildParameters(config: config)
        return try await LocalModelService.shared.sendChatRequest(
            endpoint: config.baseURL,
            messages: messages,
            model: model.isEmpty ? config.modelName : model,
            apiKey: config.apiKey,
            customHeaders: config.customHeaders,
            parameters: parameters
        )
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        guard let config = activeConfig else {
            throw AIProviderError.networkError("No local configuration found. Please set up a local model in settings.")
        }

        var apiMessages = messages
        if let last = messages.last {
            var content = last.content
            // Note: Currently LocalModelService.sendChatRequest handles standard messages.
            // If the local provider supports OpenAI-style vision content blocks,
            // we'd need to adapt sendChatRequest to accept content arrays.
            // For now, we'll keep the text content as is for local models.
            apiMessages[apiMessages.count - 1] = ChatMessage(role: last.role, content: content)
        }

        let parameters = buildParameters(config: config)
        return try await LocalModelService.shared.sendChatRequest(
            endpoint: config.baseURL,
            messages: apiMessages,
            model: model.isEmpty ? config.modelName : model,
            apiKey: config.apiKey,
            customHeaders: config.customHeaders,
            parameters: parameters
        )
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        guard let config = activeConfig else { return false }
        let result = await LocalModelService.shared.validateAndDiscover(endpoint: config.baseURL, apiKey: key, customHeaders: config.customHeaders)
        return result.success
    }

    func fetchModels(apiKey: String) async throws -> [AIModel] {
        guard let config = activeConfig else { return [] }
        let result = await LocalModelService.shared.validateAndDiscover(endpoint: config.baseURL, apiKey: config.apiKey, customHeaders: config.customHeaders)
        return result.models
    }

    private func buildParameters(config: LocalModelConfig) -> [String: Any] {
        return [
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "top_p": config.topP,
            "frequency_penalty": config.frequencyPenalty,
            "presence_penalty": config.presencePenalty,
            "seed": config.seed,
            "top_k": config.topK,
            "min_p": config.minP,
            "typical_p": config.typicalP,
            "tfs_z": config.tfsZ,
            "repeat_penalty": config.repeatPenalty,
            "repeat_last_n": config.repeatLastN,
            "mirostat": config.mirostat,
            "mirostat_tau": config.mirostatTau,
            "mirostat_eta": config.mirostatEta,
            "num_gpu": config.numGpu,
            "num_thread": config.numThread,
            "use_mlock": config.useMLock,
            "use_mmap": config.useMMap,
            "batch_size": config.batchSize,
            "context_length": config.contextLength,
            "low_vram": config.lowVRAM,
            "f16_kv": config.f16KV,
            "logits_all": config.logitsAll,
            "vocab_only": config.vocabOnly,
            "stop": config.stopSequences,
            "logprobs": config.logprobs
        ]
    }
}
