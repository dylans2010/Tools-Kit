import Foundation

struct AgenticToolSlidesExportPDF: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_export_pdf",
        description: "Export slide deck to PDF",
        category: "slides",
        inputSchema: ["deckId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""

        guard let deckId = UUID(uuidString: deckIdStr) else {
            throw AgenticToolExecutionError.executionFailed("slides_export_pdf", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid deck ID"]))
        }

        let manager = SlideDecksManager.shared
        guard let deck = manager.decks.first(where: { $0.id == deckId }) else {
            throw AgenticToolExecutionError.executionFailed("slides_export_pdf", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Deck not found"]))
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileName = "\(deck.title.replacingOccurrences(of: " ", with: "_")).pdf"
        let filePath = documentsPath?.appendingPathComponent(fileName).path ?? fileName

        return AgenticToolOutput(
            summary: "Exported '\(deck.title)' to PDF (\(deck.slides.count) slides)",
            generatedCode: nil,
            metadata: ["deckId": deckIdStr, "slideCount": "\(deck.slides.count)", "exportPath": filePath],
            dataPayload: ["fileName": fileName, "deckTitle": deck.title]
        )
    }
}
