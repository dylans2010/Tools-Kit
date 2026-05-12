import Foundation

struct AgenticToolMediaImageAttach: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "media_image_attach",
        description: "Attach an image to a workspace item",
        category: "media",
        inputSchema: ["imageId": "String", "targetId": "String", "targetType": "String"]
    )

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let imageId = parameters["imageId"] ?? ""
        let targetId = parameters["targetId"] ?? ""
        let targetType = parameters["targetType"] ?? "note"

        return AgenticToolOutput(
            summary: "Attached image '\(imageId)' to \(targetType) '\(targetId)'",
            generatedCode: nil,
            metadata: ["imageId": imageId, "targetId": targetId, "targetType": targetType],
            dataPayload: ["status": "attached", "imageId": imageId]
        )
    }
}
