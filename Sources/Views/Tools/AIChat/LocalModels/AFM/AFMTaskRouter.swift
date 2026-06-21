import Foundation

@MainActor
class AFMTaskRouter: ObservableObject {
    static let shared = AFMTaskRouter()

    private let service = AFMService.shared

    func performSummarization(text: String) async throws -> String {
        let prompt = "Summarize the following text concisely:\n\n\(text)"
        return try await service.generateResponse(prompt: prompt)
    }

    func performStructuredTask(prompt: String, taskType: String) async throws -> String {
        let systemPrompt = "You are specialized in \(taskType) tasks. Return structured output."
        return try await service.generateResponse(prompt: prompt, systemPrompt: systemPrompt)
    }
}
