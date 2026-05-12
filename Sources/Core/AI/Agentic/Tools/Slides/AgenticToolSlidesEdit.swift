import Foundation

struct AgenticToolSlidesEdit: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_edit",
        description: "Edit a specific slide",
        category: "slides",
        inputSchema: ["deckId": "String", "slideIndex": "String", "content": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""
        let slideIndexStr = parameters["slideIndex"] ?? "0"
        let content = parameters["content"] ?? ""

        guard let deckId = UUID(uuidString: deckIdStr) else {
            throw AgenticToolExecutionError.executionFailed("slides_edit", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid deck ID"]))
        }

        let slideIndex = Int(slideIndexStr) ?? 0
        let manager = SlideDecksManager.shared

        guard var deck = manager.decks.first(where: { $0.id == deckId }) else {
            throw AgenticToolExecutionError.executionFailed("slides_edit", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Deck not found"]))
        }

        guard slideIndex >= 0 && slideIndex < deck.slides.count else {
            throw AgenticToolExecutionError.executionFailed("slides_edit", NSError(domain: "AgenticTools", code: 3, userInfo: [NSLocalizedDescriptionKey: "Slide index out of range"]))
        }

        deck.slides[slideIndex].content = content
        manager.updateDeck(deck)

        return AgenticToolOutput(
            summary: "Updated slide \(slideIndex) in deck '\(deck.title)'",
            generatedCode: nil,
            metadata: ["deckId": deckIdStr, "slideIndex": slideIndexStr],
            dataPayload: ["contentLength": "\(content.count)"]
        )
    }
}
