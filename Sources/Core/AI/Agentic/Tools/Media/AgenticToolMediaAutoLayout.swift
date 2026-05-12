import Foundation
import FoundationModels

struct AgenticToolMediaAutoLayout: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "media_auto_layout",
        description: "Auto-layout media in a document or slide",
        category: "media",
        inputSchema: ["targetId": "String", "mediaIds": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let targetId = parameters["targetId"] ?? ""
        let mediaIdsStr = parameters["mediaIds"] ?? ""
        let mediaIds = mediaIdsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let session = LanguageModelSession(instructions: "You are a layout optimization AI. Suggest optimal media placement for documents and slides.")
        let response = try await session.respond(to: "Suggest optimal layout for \(mediaIds.count) media items in target '\(targetId)'. Consider visual hierarchy, balance, and readability.")

        return AgenticToolOutput(
            summary: "Auto-laid out \(mediaIds.count) media items in '\(targetId)'",
            generatedCode: nil,
            metadata: ["targetId": targetId, "mediaCount": "\(mediaIds.count)"],
            dataPayload: ["layout": response.content]
        )
    }
}
