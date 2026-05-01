import Foundation

class MessagesAIService {
    static let shared = MessagesAIService()

    private init() {}

    func process(request: MessagesAIRequest) async throws -> AIResult {
        let output: String

        switch request.subtype {
        case .rewrite:
            output = try await AIService.shared.processText(
                prompt: "Rewrite the following text with tone '\(request.parameters["tone"] ?? "neutral")' and mode '\(request.parameters["mode"] ?? "clear")':\n\n\(request.input)",
                systemPrompt: "You are a writing assistant."
            )
        case .summarize:
            output = try await AIService.shared.summarize(text: request.input)
        case .reply:
            output = try await AIService.shared.draftReply(
                to: request.input,
                from: request.parameters["sender"] ?? "Sender",
                subject: request.parameters["subject"] ?? "No Subject"
            )
        default:
            output = try await AIService.shared.generateResponse(prompt: request.input)
        }

        return AIResult(input: request.input, output: output, subtype: request.subtype)
    }
}
