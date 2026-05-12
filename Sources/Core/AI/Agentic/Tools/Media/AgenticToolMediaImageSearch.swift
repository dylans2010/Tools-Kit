import Foundation

struct AgenticToolMediaImageSearch: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "media_image_search",
        description: "Search for images and media across the workspace",
        category: "media",
        inputSchema: ["query": "String", "scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let scope = parameters["scope"] ?? "all"
        let queryLower = query.lowercased()

        var results: [String] = []

        if scope == "all" || scope == "slides" {
            for deck in SlideDecksManager.shared.decks {
                for (index, slide) in deck.slides.enumerated() {
                    if slide.title.lowercased().contains(queryLower) ||
                       slide.metadata.values.contains(where: { $0.lowercased().contains(queryLower) }) {
                        results.append("Slide \(index) in '\(deck.title)': \(slide.title)")
                    }
                }
            }
        }

        if scope == "all" || scope == "notes" {
            for notebook in NotebooksManager.shared.notebooks {
                for folder in notebook.folders {
                    for page in folder.pages {
                        for attachment in page.attachments where attachment.lowercased().contains(queryLower) {
                            results.append("Attachment '\(attachment)' in note '\(page.title)'")
                        }
                    }
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
