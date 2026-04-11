import Foundation

// MARK: - Mistral Provider

final class MistralProvider: AIProvider {
    let id = "mistral"
    let name = "Mistral"
    let icon = "wind"
    let apiKeyURL = URL(string: "https://console.mistral.ai/api-keys")
    let apiKeyPlaceholder = "..."

    let models: [AIModel] = [
        AIModel(id: "mistral-large-latest",    name: "Mistral Large",         supportsVision: false, contextLength: 128_000),
        AIModel(id: "mistral-small-latest",    name: "Mistral Small",         supportsVision: false, contextLength: 32_000),
        AIModel(id: "codestral-latest",        name: "Codestral",             supportsVision: false, contextLength: 256_000),
        AIModel(id: "open-mistral-nemo",       name: "Mistral Nemo (Free)",   supportsVision: false, contextLength: 128_000),
        AIModel(id: "pixtral-large-latest",    name: "Pixtral Large",         supportsVision: true,  contextLength: 128_000),
        AIModel(id: "pixtral-12b-2409",        name: "Pixtral 12B",           supportsVision: true,  contextLength: 128_000),
    ]

    private let endpoint = "https://api.mistral.ai/v1/chat/completions"

    func supportsVision(model: String) -> Bool {
        models.first(where: { $0.id == model })?.supportsVision ?? false
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        let request = try buildRequest(
            messages: messages.map { ["role": $0.role, "content": $0.content] },
            model: model, apiKey: apiKey
        )
        return try await performRequest(request)
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        guard supportsVision(model: model) else {
            throw AIProviderError.unsupportedFeature("Vision is not supported by \(model)")
        }
        var apiMessages: [[String: Any]] = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        if let last = messages.last {
            var content: [[String: Any]] = [["type": "text", "text": last.content]]
            for att in attachments where att.mimeType.hasPrefix("image/") {
                let b64 = att.data.base64EncodedString()
                content.append(["type": "image_url", "image_url": ["url": "data:\(att.mimeType);base64,\(b64)"]])
            }
            apiMessages.append(["role": last.role, "content": content])
        }
        let request = try buildRequest(messages: apiMessages, model: model, apiKey: apiKey)
        return try await performRequest(request)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "https://api.mistral.ai/v1/models")!)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func buildRequest(messages: [[String: Any]], model: String, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": model, "messages": messages]
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
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        guard let text = message?["content"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}
