import Foundation

// MARK: - Google Gemini Provider

final class GeminiProvider: AIProvider {
    let id = "gemini"
    let name = "Google Gemini"
    let icon = "g.circle.fill"
    let apiKeyURL = URL(string: "https://aistudio.google.com/app/apikey")
    let apiKeyPlaceholder = "AIza..."

    let models: [AIModel] = [
        AIModel(id: "gemini-2.0-flash",        name: "Gemini 2.0 Flash",        supportsVision: true,  contextLength: 1_048_576),
        AIModel(id: "gemini-2.0-flash-lite",   name: "Gemini 2.0 Flash Lite",   supportsVision: true,  contextLength: 1_048_576),
        AIModel(id: "gemini-1.5-pro",          name: "Gemini 1.5 Pro",          supportsVision: true,  contextLength: 2_097_152),
        AIModel(id: "gemini-1.5-flash",        name: "Gemini 1.5 Flash",        supportsVision: true,  contextLength: 1_048_576),
        AIModel(id: "gemini-1.5-flash-8b",     name: "Gemini 1.5 Flash 8B",     supportsVision: true,  contextLength: 1_048_576),
    ]

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    func supportsVision(model: String) -> Bool {
        models.first(where: { $0.id == model })?.supportsVision ?? true
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (systemInstruction, chatMessages) = splitSystem(messages)
        var body: [String: Any] = ["contents": buildContents(chatMessages)]
        if let sys = systemInstruction {
            body["systemInstruction"] = ["parts": [["text": sys]]]
        }
        body["generationConfig"] = ["maxOutputTokens": 8192]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await performRequest(request)
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (systemInstruction, chatMessages) = splitSystem(messages)
        var contents = buildContents(chatMessages.dropLast())

        if let last = chatMessages.last {
            var parts: [[String: Any]] = []
            for att in attachments {
                if att.mimeType.hasPrefix("image/") {
                    let b64 = att.data.base64EncodedString()
                    parts.append(["inlineData": ["mimeType": att.mimeType, "data": b64]])
                }
            }
            parts.append(["text": last.content])
            contents.append(["role": geminiRole(last.role), "parts": parts])
        }

        var body: [String: Any] = ["contents": contents]
        if let sys = systemInstruction {
            body["systemInstruction"] = ["parts": [["text": sys]]]
        }
        body["generationConfig"] = ["maxOutputTokens": 8192]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await performRequest(request)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)?key=\(key)")!
        let (_, response) = try await URLSession.shared.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func splitSystem(_ messages: [ChatMessage]) -> (String?, [ChatMessage]) {
        let sys = messages.filter { $0.role == "system" }.map { $0.content }.joined(separator: "\n")
        let rest = messages.filter { $0.role != "system" }
        return (sys.isEmpty ? nil : sys, rest)
    }

    private func geminiRole(_ role: String) -> String {
        role == "assistant" ? "model" : "user"
    }

    private func buildContents(_ messages: [ChatMessage]) -> [[String: Any]] {
        // Gemini requires alternating user/model turns; merge consecutive same-role messages
        var merged: [[String: Any]] = []
        for msg in messages {
            let role = geminiRole(msg.role)
            let part: [String: Any] = ["text": msg.content]
            if let last = merged.last, last["role"] as? String == role,
               var parts = merged[merged.count - 1]["parts"] as? [[String: Any]] {
                parts.append(part)
                merged[merged.count - 1]["parts"] = parts
            } else {
                merged.append(["role": role, "parts": [part]])
            }
        }
        return merged
    }

    private func buildContents(_ messages: any Collection<ChatMessage>) -> [[String: Any]] {
        buildContents(Array(messages))
    }

    private func performRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw AIProviderError.networkError(body)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}
