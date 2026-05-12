import Foundation

enum RewriteTone: String, CaseIterable, Sendable {
    case professional = "Professional"
    case formal = "Formal"
    case casual = "Casual"
    case concise = "Concise"
}

class TextRewriterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var rewrittenText = ""
    @Published var isProcessing = false

    @MainActor
    func rewrite(to tone: RewriteTone) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        Rewrite the following text in a \(tone.rawValue.lowercased()) tone.
        Keep the original meaning.
        Text:
        \(text)
        """

        do {
            rewrittenText = try await AIService.shared.generateResponse(prompt: prompt)
        } catch {
            rewrittenText = "Failed to rewrite text: \(error.localizedDescription)"
        }
    }
}
