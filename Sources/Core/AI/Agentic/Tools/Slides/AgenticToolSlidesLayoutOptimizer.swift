import Foundation
import FoundationModels

struct AgenticToolSlidesLayoutOptimizer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_layout_optimizer",
        description: "Optimize slide layouts using AI",
        category: "slides",
        inputSchema: ["deckId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""

        guard let deckId = UUID(uuidString: deckIdStr) else {
            throw AgenticToolExecutionError.executionFailed("slides_layout_optimizer", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid deck ID"]))
        }

        let manager = SlideDecksManager.shared
        guard let deck = manager.decks.first(where: { $0.id == deckId }) else {
            throw AgenticToolExecutionError.executionFailed("slides_layout_optimizer", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Deck not found"]))
        }

        let slideDescriptions = deck.slides.enumerated().map { "Slide \($0.offset): \($0.element.title)" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a slide layout optimization AI. Analyze slide content and suggest optimal layouts.")
        let prompt = """
        Optimize the layout for this slide deck: '\(deck.title)'
        Slides:
        \(slideDescriptions)

        For each slide, suggest:
        1. Optimal layout type (full-width, two-column, image-focused, etc.)
        2. Content placement
        3. Visual hierarchy
        4. Spacing and alignment recommendations
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Optimized layouts for \(deck.slides.count) slides in '\(deck.title)'",
            generatedCode: nil,
            metadata: ["deckId": deckIdStr, "slideCount": "\(deck.slides.count)"],
            dataPayload: ["optimizations": response.content]
        )
    }
}
