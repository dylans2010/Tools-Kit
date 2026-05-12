import Foundation

struct AgenticToolSlidesEdit: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_edit",
        description: "Edit a specific slide's title, bullets, speaker notes, or layout",
        category: "slides",
        inputSchema: ["deckId": "String", "slideIndex": "String", "field": "String", "value": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""
        let slideIndexStr = parameters["slideIndex"] ?? "0"
        let field = parameters["field"] ?? "title"
        let value = parameters["value"] ?? ""

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

        switch field.lowercased() {
        case "title":
            deck.slides[slideIndex].title = value
        case "bullets":
            deck.slides[slideIndex].bullets = value.components(separatedBy: "\n").filter { !$0.isEmpty }
        case "speakernotes":
            deck.slides[slideIndex].speakerNotes = value
        case "layout":
            deck.slides[slideIndex].layout = value
        case "type":
            deck.slides[slideIndex].type = value
        case "background":
            deck.slides[slideIndex].backgroundColorHex = value
        default:
            deck.slides[slideIndex].title = value
        }

        manager.updateDeck(deck)

        return AgenticToolOutput(
            summary: "Updated slide \(slideIndex) \(field) in deck '\(deck.title)'",
            generatedCode: nil,
            metadata: ["deckId": deckIdStr, "slideIndex": slideIndexStr, "field": field],
            dataPayload: ["updatedValue": value]
        )
    }
}
