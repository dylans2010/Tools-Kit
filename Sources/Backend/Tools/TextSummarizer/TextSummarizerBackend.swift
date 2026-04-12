import Foundation

class TextSummarizerBackend: ObservableObject {
    @Published var inputText = ""
    @Published var summaryText = ""
    @Published var isLoading = false
    @Published var sentenceCount: Double = 3

    @MainActor
    func summarize() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            summaryText = ""
            return
        }

        isLoading = true
        defer { isLoading = false }
        let prompt = """
        Summarize the following text in \(Int(sentenceCount)) sentences.
        Keep key facts and action items.
        Text:
        \(text)
        """
        do {
            summaryText = try await AIService.shared.generateResponse(prompt: prompt)
        } catch {
            summaryText = "Failed to summarize: \(error.localizedDescription)"
        }
    }
}
