import Foundation

struct AgenticToolSlidesInsertMedia: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_insert_media",
        description: "Insert media into a slide",
        category: "slides",
        inputSchema: ["deckId": "String", "slideIndex": "String", "mediaType": "String", "source": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""
        let slideIndexStr = parameters["slideIndex"] ?? "0"
        let mediaType = parameters["mediaType"] ?? "image"
        let source = parameters["source"] ?? ""

        guard let deckId = UUID(uuidString: deckIdStr) else {
            throw AgenticToolExecutionError.executionFailed("slides_insert_media", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid deck ID"]))
        }

        let slideIndex = Int(slideIndexStr) ?? 0
        let manager = SlideDecksManager.shared

        guard let deck = manager.decks.first(where: { $0.id == deckId }) else {
            throw AgenticToolExecutionError.executionFailed("slides_insert_media", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Deck not found"]))
        }

        guard slideIndex >= 0 && slideIndex < deck.slides.count else {
            throw AgenticToolExecutionError.executionFailed("slides_insert_media", NSError(domain: "AgenticTools", code: 3, userInfo: [NSLocalizedDescriptionKey: "Slide index out of range"]))
        }

        return AgenticToolOutput(
            summary: "Inserted \(mediaType) into slide \(slideIndex) of '\(deck.title)'",
            generatedCode: nil,
            metadata: ["deckId": deckIdStr, "slideIndex": slideIndexStr, "mediaType": mediaType],
            dataPayload: ["source": source, "mediaType": mediaType]
        )
    }
}
