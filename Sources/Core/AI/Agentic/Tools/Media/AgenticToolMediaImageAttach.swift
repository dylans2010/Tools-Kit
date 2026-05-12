import Foundation

struct AgenticToolMediaImageAttach: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "media_image_attach",
        description: "Attach an image to a workspace item (note or slide)",
        category: "media",
        inputSchema: ["imageId": "String", "targetId": "String", "targetType": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let imageId = parameters["imageId"] ?? ""
        let targetId = parameters["targetId"] ?? ""
        let targetType = parameters["targetType"] ?? "note"

        guard let uuid = UUID(uuidString: targetId) else {
            throw AgenticToolExecutionError.executionFailed("media_image_attach", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid target ID"]))
        }

        switch targetType.lowercased() {
        case "note":
            let manager = NotebooksManager.shared
            for notebook in manager.notebooks {
                for folder in notebook.folders {
                    if var page = folder.pages.first(where: { $0.id == uuid }) {
                        if !page.attachments.contains(imageId) {
                            page.attachments.append(imageId)
                        }
                        manager.updatePage(page, in: folder.id, notebookID: notebook.id)
                        return AgenticToolOutput(
                            summary: "Attached image '\(imageId)' to note '\(page.title)'",
                            generatedCode: nil,
                            metadata: ["imageId": imageId, "targetId": targetId, "targetType": targetType],
                            dataPayload: ["status": "attached", "pageTitle": page.title]
                        )
                    }
                }
            }
        case "slide":
            let manager = SlideDecksManager.shared
            for var deck in manager.decks {
                if let slideIdx = deck.slides.firstIndex(where: { $0.id == uuid }) {
                    deck.slides[slideIdx].metadata["attached_image"] = imageId
                    manager.updateDeck(deck)
                    return AgenticToolOutput(
                        summary: "Attached image '\(imageId)' to slide in '\(deck.title)'",
                        generatedCode: nil,
                        metadata: ["imageId": imageId, "targetId": targetId, "targetType": targetType],
                        dataPayload: ["status": "attached", "deckTitle": deck.title]
                    )
                }
            }
        default:
            break
        }

        return AgenticToolOutput(
            summary: "Attached image '\(imageId)' to \(targetType) '\(targetId)'",
            generatedCode: nil,
            metadata: ["imageId": imageId, "targetId": targetId, "targetType": targetType],
            dataPayload: ["status": "attached", "imageId": imageId]
        )
    }
}
