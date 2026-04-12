import Foundation

final class ReasoningToolBackend: ObservableObject {
    @Published var thoughtProcess: String = ""
    @Published var isProcessing = false

    func execute(problem: String) async throws -> String {
        return try await AIService.shared.generateResponse(prompt: "Solve this problem by thinking step-by-step. Provide your full reasoning:\n\n\(problem)")
    }

    func solve(problem: String) async {
        await MainActor.run { isProcessing = true }
        let prompt = "Solve this problem by thinking step-by-step. Provide your full reasoning:\n\n\(problem)"
        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            await MainActor.run {
                self.thoughtProcess = response
                self.isProcessing = false
            }
        } catch {
            await MainActor.run { isProcessing = false }
        }
    }
}
