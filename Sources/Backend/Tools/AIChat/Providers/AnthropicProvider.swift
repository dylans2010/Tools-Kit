import Foundation

// MARK: - Anthropic Provider

final class AnthropicProvider: AIProvider {
    let id = "anthropic"
    let name = "Anthropic"
    let icon = "a.circle.fill"
    let apiKeyURL = URL(string: "https://console.anthropic.com/settings/keys")
    let apiKeyPlaceholder = "sk-ant-..."

    let models: [AIModel] = []

    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let anthropicVersion = "2023-06-01"

    func supportsVision(model: String) -> Bool {
        model.lowercased().contains("claude")
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        let (systemPrompt, userMessages) = splitSystemMessages(messages)
        let apiMessages = userMessages.map { ["role": roleFor($0.role), "content": $0.content] }
        let request = try buildRequest(messages: apiMessages, systemPrompt: systemPrompt,
                                       model: model, apiKey: apiKey)
        return try await performRequest(request)
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        let (systemPrompt, userMessages) = splitSystemMessages(messages)
        var apiMessages: [[String: Any]] = userMessages.dropLast().map {
            ["role": roleFor($0.role), "content": $0.content]
        }
        if let last = userMessages.last {
            var content: [[String: Any]] = []
            for att in attachments {
                if att.mimeType.hasPrefix("image/") {
                    let b64 = att.data.base64EncodedString()
                    content.append([
                        "type": "image",
                        "source": ["type": "base64", "media_type": att.mimeType, "data": b64]
                    ])
                }
            }
            content.append(["type": "text", "text": last.content])
            apiMessages.append(["role": roleFor(last.role), "content": content])
        }
        let request = try buildRequest(messages: apiMessages, systemPrompt: systemPrompt,
                                       model: model, apiKey: apiKey)
        return try await performRequest(request)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        // A minimal valid request; 200 = valid key, 401 = invalid key, other errors = network/config issue
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(key, forHTTPHeaderField: "x-api-key")
        request.addValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        // 200 = success, 401 = invalid key
        return code == 200
    }

    func fetchModels(apiKey: String) async throws -> [AIModel] {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models")!)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return []
        }
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = object?["data"] as? [[String: Any]] ?? []
        return rows.compactMap { row in
            guard let id = row["id"] as? String else { return nil }
            let name = (row["display_name"] as? String) ?? id
            return AIModel(id: id, name: name, supportsVision: id.lowercased().contains("claude"), contextLength: nil)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func roleFor(_ role: String) -> String {
        role == "assistant" ? "assistant" : "user"
    }

    private func splitSystemMessages(_ messages: [ChatMessage]) -> (String?, [ChatMessage]) {
        let system = messages.filter { $0.role == "system" }.map { $0.content }.joined(separator: "\n")
        let rest = messages.filter { $0.role != "system" }
        return (system.isEmpty ? nil : system, rest)
    }

    private func buildRequest(messages: [[String: Any]], systemPrompt: String?,
                              model: String, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["model": model, "max_tokens": 4096, "messages": messages]
        if let sp = systemPrompt { body["system"] = sp }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw AIProviderError.networkError(body)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]]
        guard let text = content?.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}
