import Foundation

struct ChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct ChatAttachment: Sendable {
    let data: Data
    let mimeType: String
    let fileName: String
}

class OpenRouterService {
    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"

    static func supportsVision(model: String) -> Bool {
        let lower = model.lowercased()
        return lower.contains("vision") || lower.contains("claude") ||
               lower.contains("gpt-4o") || lower.contains("gemini") ||
               lower.contains("llava") || lower.contains("qwen-vl") ||
               lower.contains("pixtral")
    }

    func sendMessage(messages: [ChatMessage], apiKey: String, model: String = "google/gemini-2.0-flash-exp:free") async throws -> String {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://tools-kit.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Tools Kit", forHTTPHeaderField: "X-Title")

        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OpenRouter", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to get response from AI. Body: \(responseText)"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }

    func sendMessageWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://tools-kit.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("Tools Kit", forHTTPHeaderField: "X-Title")

        var apiMessages: [[String: Any]] = messages.dropLast().map { ["role": $0.role, "content": $0.content] }

        if let lastMessage = messages.last {
            var contentArray: [[String: Any]] = [["type": "text", "text": lastMessage.content]]
            for attachment in attachments {
                let base64 = attachment.data.base64EncodedString()
                let imageURL = "data:\(attachment.mimeType);base64,\(base64)"
                contentArray.append([
                    "type": "image_url",
                    "image_url": ["url": imageURL]
                ])
            }
            apiMessages.append(["role": lastMessage.role, "content": contentArray])
        }

        let body: [String: Any] = ["model": model, "messages": apiMessages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OpenRouter", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to get response from AI. Body: \(responseText)"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }
}
