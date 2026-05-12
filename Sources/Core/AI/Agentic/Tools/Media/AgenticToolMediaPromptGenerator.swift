import Foundation
import FoundationModels

struct AgenticToolMediaPromptGenerator: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "media_prompt_generator",
        description: "Generate image prompts using AI",
        category: "media",
        inputSchema: ["description": "String", "style": "String"]
    )

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let description = parameters["description"] ?? ""
        let style = parameters["style"] ?? "photorealistic"

        let session = LanguageModelSession(instructions: "You are an image prompt engineering expert. Generate detailed, effective image generation prompts.")
        let response = try await session.respond(to: "Generate a detailed image generation prompt for: \(description)\nStyle: \(style)\n\nInclude composition, lighting, color palette, and mood details.")

        return AgenticToolOutput(
            summary: "Generated image prompt for '\(description)' in '\(style)' style",
            generatedCode: nil,
            metadata: ["description": description, "style": style],
            dataPayload: ["prompt": response.content]
        )
    }
}
