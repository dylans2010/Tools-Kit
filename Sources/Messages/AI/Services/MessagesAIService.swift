import Foundation
import UIKit

final class MessagesAIService {
    static let shared = MessagesAIService()

    private let session: URLSession
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let model = "openrouter/free"

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func process(request: MessagesAIRequest) async throws -> AIResult {
        let payload = buildPrompt(for: request)
        let output = try await sendChat(prompt: payload.prompt, systemPrompt: payload.systemPrompt)
        return AIResult(input: request.input, output: output, subtype: request.subtype)
    }

    private func buildPrompt(for request: MessagesAIRequest) -> (systemPrompt: String, prompt: String) {
        switch request.subtype {
        case .rewrite:
            let tone = request.parameters["tone"] ?? "neutral"
            let mode = request.parameters["mode"] ?? "clear"
            return (
                "You are a writing assistant.",
                "Rewrite the following text with tone '\(tone)' and mode '\(mode)':\n\n\(request.input)"
            )

        case .summarize:
            return (
                "You are a concise summarization assistant.",
                "Summarize the following text with key points and action items:\n\n\(request.input)"
            )

        case .reply:
            let sender = request.parameters["sender"] ?? "Sender"
            let subject = request.parameters["subject"] ?? "No Subject"
            return (
                "You are an expert executive assistant who writes concise, professional email replies.",
                "Draft a polished reply to this message.\nSender: \(sender)\nSubject: \(subject)\n\nMessage:\n\(request.input)"
            )

        default:
            return (
                "You are a helpful assistant.",
                request.input
            )
        }
    }

    private func sendChat(prompt: String, systemPrompt: String) async throws -> String {
        let apiKey = try resolveAPIKey()

        let requestBody = ChatCompletionsRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: prompt)
            ]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MessagesAIServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown network error"
            throw MessagesAIServiceError.networkError(errorText)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw MessagesAIServiceError.invalidResponse
        }

        return normalize(content)
    }

    private func resolveAPIKey() throws -> String {
        let appGroupDefaults = UserDefaults(suiteName: "group.com.toolskit.app")
        let candidates = [
            "openrouterAPIKey",
            "openrouter_api_key",
            "OPENROUTER_API_KEY",
            "ai.openrouter.key",
            "AIChat_OpenRouter_APIKey"
        ]

        for key in candidates {
            if let value = appGroupDefaults?.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
            if let value = UserDefaults.standard.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        throw MessagesAIServiceError.missingAPIKey
    }

    private func normalize(_ response: String) -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else {
            return trimmed
        }

        return trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatCompletionsRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionsResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: AssistantMessage
    }

    struct AssistantMessage: Codable {
        let content: String
    }
}

enum MessagesAIServiceError: LocalizedError {
    case missingAPIKey
    case networkError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing OpenRouter API key. Save it in shared defaults before using Messages AI."
        case .networkError(let message):
            return message
        case .invalidResponse:
            return "Invalid AI response."
        }
    }
}
