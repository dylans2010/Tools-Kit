import Foundation
import FoundationModels

struct AgenticToolSlidesThemeSystem: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_theme_system",
        description: "Apply or generate a theme for slides",
        category: "slides",
        inputSchema: ["deckId": "String", "theme": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let deckIdStr = parameters["deckId"] ?? ""
        let theme = parameters["theme"] ?? "modern"

        let session = LanguageModelSession(instructions: "You are a SwiftUI theme generator. Create complete, compilable theme configurations for slide presentations.")
        let prompt = """
        Generate a SwiftUI theme system for a slide deck.
        Theme style: \(theme)
        Deck ID: \(deckIdStr)

        Include:
        1. Color palette definition
        2. Typography styles
        3. Layout configurations
        4. Background views
        5. Accent element styles
        Generate complete, compilable Swift code with all imports.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated '\(theme)' theme for deck '\(deckIdStr)'",
            generatedCode: response.content,
            metadata: ["deckId": deckIdStr, "theme": theme],
            dataPayload: ["themeApplied": theme]
        )
    }
}
