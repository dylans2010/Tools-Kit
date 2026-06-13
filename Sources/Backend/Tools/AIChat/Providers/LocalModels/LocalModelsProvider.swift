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

        let request = try buildRequest(messages: messages.map { ["role": $0.role, "content": $0.content] },
                                       model: model, config: config)
        return try await performRequest(request, timeout: config.timeout)
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        guard let config = activeConfig else {
            throw AIProviderError.networkError("No local configuration found. Please set up a local model in settings.")
        }

        var apiMessages: [[String: Any]] = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        if let last = messages.last {
            var content: [[String: Any]] = [["type": "text", "text": last.content]]
            for att in attachments {
                let b64 = att.data.base64EncodedString()
                content.append(["type": "image_url", "image_url": ["url": "data:\(att.mimeType);base64,\(b64)"]])
            }
            apiMessages.append(["role": last.role, "content": content])
        }

        let request = try buildRequest(messages: apiMessages, model: model, config: config)
        return try await performRequest(request, timeout: config.timeout)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        // For local models, we can use a simple model list check as a "validation"
        guard let config = activeConfig else { return false }
        do {
            let _ = try await fetchModels(apiKey: key)
            return true
        } catch {
            return false
        }
    }

    func fetchModels(apiKey: String) async throws -> [AIModel] {
        guard let config = activeConfig else {
            return []
        }

        // Try OpenAI compatible /v1/models first
        let openaiURL = URL(string: config.baseURL.replacingOccurrences(of: "/chat/completions", with: "") + "/models")
        if let url = openaiURL {
            var request = URLRequest(url: url)
            if !config.apiKey.isEmpty {
                request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            }
            config.customHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    return try ProviderModelFetchSupport.parseModelArray(data)
                }
            } catch {
                // Fallback to Ollama if OpenAI fails
            }
        }

        // Try Ollama /api/tags
        let ollamaURL = URL(string: config.baseURL.replacingOccurrences(of: "/v1", with: "") + "/api/tags")
        if let url = ollamaURL {
            var request = URLRequest(url: url)
            config.customHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    return try parseOllamaModels(data)
                }
            } catch {
                // Ignore and return empty
            }
        }

        return []
    }

    private func buildRequest(messages: [[String: Any]], model: String, config: LocalModelConfig) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: config.baseURL) else {
            throw AIProviderError.networkError("Invalid Base URL")
        }

        // Ensure path ends with /chat/completions if not already present
        if !urlComponents.path.contains("/chat/completions") {
            if urlComponents.path.hasSuffix("/") {
                urlComponents.path += "chat/completions"
            } else if urlComponents.path.isEmpty {
                urlComponents.path = "/v1/chat/completions"
            } else {
                urlComponents.path += "/chat/completions"
            }
        }

        guard let url = urlComponents.url else {
            throw AIProviderError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !config.apiKey.isEmpty {
            request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        config.customHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        var body: [String: Any] = [
            "model": config.modelName, // Prefer configured model name
            "messages": messages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "top_p": config.topP,
            "frequency_penalty": config.frequencyPenalty,
            "presence_penalty": config.presencePenalty,
            "stream": false, // Disable streaming for compatibility with performRequest (standard dataTask)

            // Advanced Sampling
            "seed": config.seed,
            "top_k": config.topK,
            "min_p": config.minP,
            "typical_p": config.typicalP,
            "tfs_z": config.tfsZ,

            // Penalties
            "repeat_penalty": config.repeatPenalty,
            "repeat_last_n": config.repeatLastN,

            // Mirostat
            "mirostat": config.mirostat,
            "mirostat_tau": config.mirostatTau,
            "mirostat_eta": config.mirostatEta,

            // Performance & System
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

            // Interaction
            "stop": config.stopSequences,
            "logprobs": config.logprobs
        ]

        // If the call provided a specific model ID, override
        if !model.isEmpty && model != config.modelName {
            body["model"] = model
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func performRequest(_ request: URLRequest, timeout: Double) async throws -> String {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw AIProviderError.networkError("Server returned \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(body)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        guard let text = message?["content"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }

    private func parseOllamaModels(_ data: Data) throws -> [AIModel] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any], let models = root["models"] as? [[String: Any]] else {
            return []
        }

        return models.compactMap { row in
            guard let name = row["name"] as? String else { return nil }
            let lowered = name.lowercased()
            let vision = lowered.contains("vision") || lowered.contains("llava")
            return AIModel(id: name, name: name, supportsVision: vision)
        }
    }
}
