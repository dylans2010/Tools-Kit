import Foundation

@MainActor
final class IdeaGeneratorBackend: ObservableObject {
    @Published var ideas: [String] = []
    @Published var topic: String = ""
    @Published var isProcessing = false

    func generate() async {
        isProcessing = true
        defer { isProcessing = false }

        let focus = topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "a useful app or startup" : topic
        let prompt = """
        Generate 5 concise and practical product ideas about \(focus).
        Return each idea as a single bullet with a short one-line rationale.
        """

        do {
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            let rows = response
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            ideas = Array(rows.prefix(10))
        } catch {
            ideas = ["Failed to generate ideas: \(error.localizedDescription)"]
        }
    }

    func clear() {
        ideas = []
    }
}
