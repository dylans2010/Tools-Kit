import Foundation

// MARK: - OpenRouter Provider

final class OpenRouterProvider: AIProvider {
    let id = "openrouter"
    let name = "OpenRouter"
    let icon = "network"
    let apiKeyURL = URL(string: "https://openrouter.ai/keys")
    let apiKeyPlaceholder = "sk-or-v1-..."

    let models: [AIModel] = [
        AIModel(id: "google/gemini-2.0-flash-exp:free", name: "Gemini 2.0 Flash (Free)", supportsVision: true, contextLength: 1_048_576),
        AIModel(id: "anthropic/claude-3.5-sonnet",      name: "Claude 3.5 Sonnet",       supportsVision: true, contextLength: 200_000),
        AIModel(id: "anthropic/claude-3-haiku",         name: "Claude 3 Haiku",           supportsVision: true, contextLength: 200_000),
        AIModel(id: "openai/gpt-4o",                    name: "GPT-4o",                   supportsVision: true, contextLength: 128_000),
        AIModel(id: "openai/gpt-4o-mini",               name: "GPT-4o Mini",              supportsVision: true, contextLength: 128_000),
        AIModel(id: "mistralai/mistral-large",           name: "Mistral Large",            supportsVision: false, contextLength: 128_000),
        AIModel(id: "meta-llama/llama-3.1-70b-instruct", name: "Llama 3.1 70B",           supportsVision: false, contextLength: 131_072),
        AIModel(id: "qwen/qwen-2.5-72b-instruct",        name: "Qwen 2.5 72B",            supportsVision: false, contextLength: 128_000),
    ]

    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"

    func supportsVision(model: String) -> Bool {
        if let m = models.first(where: { $0.id == model }) { return m.supportsVision }
        let l = model.lowercased()
        return l.contains("vision") || l.contains("claude") || l.contains("gpt-4o")
            || l.contains("gemini") || l.contains("llava") || l.contains("pixtral")
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://tools-kit.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Tools Kit", forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await performRequest(request)
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://tools-kit.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Tools Kit", forHTTPHeaderField: "X-Title")

        var apiMessages: [[String: Any]] = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        if let last = messages.last {
            var content: [[String: Any]] = [["type": "text", "text": last.content]]
            for att in attachments {
                let b64 = att.data.base64EncodedString()
                content.append(["type": "image_url", "image_url": ["url": "data:\(att.mimeType);base64,\(b64)"]])
            }
            apiMessages.append(["role": last.role, "content": content])
        }

        let body: [String: Any] = ["model": model, "messages": apiMessages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await performRequest(request)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func performRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw AIProviderError.networkError(body)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        guard let text = message?["content"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}
