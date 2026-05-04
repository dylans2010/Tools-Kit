import Foundation

@MainActor
class AIOrchestrator: ObservableObject {
    static let shared = AIOrchestrator()

    @Published var isProcessing = false
    @Published var lastResponse: String?

    private init() {}

    func query(prompt: String, context: [String: Any] = [:]) async -> String {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await AIService.shared.processText(prompt: prompt)
            self.lastResponse = response
            return response
        } catch {
            let errorMsg = "AI Orchestrator Error: \(error.localizedDescription)"
            self.lastResponse = errorMsg
            return errorMsg
        }
    }
}
