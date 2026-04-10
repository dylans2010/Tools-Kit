import Foundation
import Combine

enum AIProvider {
    case openRouter
    case coreML
}

struct AIRequest {
    let prompt: String
    let systemPrompt: String?
    let model: String?
    let attachments: [Data]?
}

class AIService: ObservableObject {
    private let openRouter: OpenRouterService

    init(openRouter: OpenRouterService = OpenRouterService()) {
        self.openRouter = openRouter
    }

    func process(request: AIRequest, provider: AIProvider = .openRouter) async throws -> String {
        switch provider {
        case .openRouter:
            return try await processWithOpenRouter(request)
        case .coreML:
            return try await processWithCoreML(request)
        }
    }

    private func processWithOpenRouter(_ request: AIRequest) async throws -> String {
        guard let apiKey = APIKeyManager.shared.getKey() else {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenRouter API Key not found"])
        }

        let messages = [
            ChatMessage(role: "system", content: request.systemPrompt ?? "You are a helpful assistant."),
            ChatMessage(role: "user", content: request.prompt)
        ]

        if let attachments = request.attachments, !attachments.isEmpty {
            let chatAttachments = attachments.map { ChatAttachment(data: $0, mimeType: "image/jpeg", fileName: "image.jpg") }
            return try await openRouter.sendMessageWithAttachments(
                messages: messages,
                attachments: chatAttachments,
                model: request.model ?? "google/gemini-2.0-flash-exp:free",
                apiKey: apiKey
            )
        } else {
            return try await openRouter.sendMessage(
                messages: messages,
                apiKey: apiKey,
                model: request.model ?? "google/gemini-2.0-flash-exp:free"
            )
        }
    }

    private func processWithCoreML(_ request: AIRequest) async throws -> String {
        // Simple local fallback if OpenRouter is unavailable or explicitly requested
        return "CoreML analysis (Local): \(request.prompt.prefix(100))..."
    }
}
