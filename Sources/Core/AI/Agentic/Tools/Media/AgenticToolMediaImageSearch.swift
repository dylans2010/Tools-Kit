import Foundation

struct AgenticToolMediaImageSearch: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "media_image_search",
        description: "Search for images in the workspace",
        category: "media",
        inputSchema: ["query": "String", "scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let scope = parameters["scope"] ?? "all"

        var results: [String] = []

        for deck in SlideDecksManager.shared.decks {
            for (index, slide) in deck.slides.enumerated() {
                if slide.title.lowercased().contains(query.lowercased()) {
                    results.append("Slide \(index) in '\(deck.title)': \(slide.title)")
                }
            }
        }

        var payload: [String: String] = ["resultCount": "\(results.count)"]
        for (index, result) in results.prefix(20).enumerated() {
            payload["result_\(index)"] = result
        }

        return AgenticToolOutput(
            summary: "Found \(results.count) media items matching '\(query)' in scope '\(scope)'",
            generatedCode: nil,
            metadata: ["query": query, "scope": scope, "resultCount": "\(results.count)"],
            dataPayload: payload
        )
    }
}
