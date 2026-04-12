import Foundation

final class ContextSummarizerBackend: ObservableObject {
    @Published var summary: String = ""
    @Published var isProcessing = false

    func summarize(text: String, context: String) async {
        await MainActor.run { isProcessing = true }
        let prompt = "Summarize the following text within the context of '\(context)':\n\n\(text)"
        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            await MainActor.run {
                self.summary = response
                self.isProcessing = false
            }
        } catch {
            await MainActor.run { isProcessing = false }
        }
    }
}
