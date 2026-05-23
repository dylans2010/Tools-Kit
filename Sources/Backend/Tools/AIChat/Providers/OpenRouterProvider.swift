import Foundation

// MARK: - OpenRouter Provider

final class OpenRouterProvider: AIProvider {
    let id = "openrouter"
    let name = "OpenRouter"
    let icon = "network"
    let apiKeyURL = URL(string: "https://openrouter.ai/keys")
    let apiKeyPlaceholder = "sk-or-v1-..."

    let models: [AIModel] = []

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
            var additionalTextContext = ""

            for att in attachments {
                if att.mimeType.hasPrefix("image") {
                    let b64 = att.data.base64EncodedString()
                    content.append([
                        "type": "image_url",
                        "image_url": ["url": "data:\(att.mimeType);base64,\(b64)"]
                    ])
                } else if att.mimeType == "text/plain", let text = String(data: att.data, encoding: .utf8) {
                    additionalTextContext += "\n\n--- Attachment: \(att.fileName) ---\n\(text)"
                } else {
                    additionalTextContext += "\n\n[Attachment: \(att.fileName) (\(att.mimeType)) - Binary content not directly viewable]"
                }
            }

            if !additionalTextContext.isEmpty {
                if var textPart = content.first(where: { ($0["type"] as? String) == "text" }),
                   let originalText = textPart["text"] as? String {
                    textPart["text"] = originalText + additionalTextContext
                    content[0] = textPart
                }
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

    func fetchModels(apiKey: String) async throws -> [AIModel] {
        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("https://tools-kit.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Tools Kit", forHTTPHeaderField: "X-Title")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return []
        }
        return try ProviderModelFetchSupport.parseModelArray(data)
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
