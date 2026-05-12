import Foundation
import FoundationModels

struct AgenticToolSlidesBuildRenderer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_build_renderer",
        description: "Build a renderer for slide content",
        category: "slides",
        inputSchema: ["deckId": "String", "format": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""
        let format = parameters["format"] ?? "swiftui"

        let session = LanguageModelSession(instructions: "You are a Swift code generator. Generate complete, compilable SwiftUI view code for rendering slides.")
        let prompt = """
        Generate a SwiftUI slide renderer component.
        Format: \(format)
        Deck ID: \(deckIdStr)

        The renderer should:
        1. Display slide title and content
        2. Support navigation between slides
        3. Include transition animations
        4. Be a complete, compilable SwiftUI View
        Include all necessary imports.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated \(format) renderer for deck '\(deckIdStr)'",
            generatedCode: response.content,
            metadata: ["deckId": deckIdStr, "format": format],
            dataPayload: ["rendererType": format]
        )
    }
}
