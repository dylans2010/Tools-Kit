import Foundation
import FoundationModels

struct AgenticToolSlidesGenerate: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "slides_generate",
        description: "Generate a complete slide deck from a topic",
        category: "slides",
        inputSchema: ["topic": "String", "slideCount": "String", "style": "String"],
        producesCode: true
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let topic = parameters["topic"] ?? ""
        let slideCountStr = parameters["slideCount"] ?? "5"
        let style = parameters["style"] ?? "professional"
        let slideCount = Int(slideCountStr) ?? 5

        let session = LanguageModelSession(instructions: "You are a slide deck generator. Create complete, well-structured slide content with titles, bullet points, and speaker notes.")
        let prompt = """
        Generate a \(slideCount)-slide presentation about: \(topic)
        Style: \(style)

        For each slide, provide:
        1. Title
        2. Content (bullet points)
        3. Speaker notes
        4. Layout suggestion
        """

        let response = try await session.respond(to: prompt)

        let manager = SlideDecksManager.shared
        var slides: [Slide] = []
        for i in 0..<slideCount {
            slides.append(Slide(
                type: i == 0 ? "title" : "content",
                title: "\(topic) - Slide \(i + 1)",
                layout: i == 0 ? "title" : "bullets"
            ))
        }
        let deck = SlideDeck(title: topic, theme: style, slides: slides)
        manager.addDeck(deck)

        return AgenticToolOutput(
            summary: "Generated \(slideCount)-slide deck about '\(topic)'",
            generatedCode: response.content,
            metadata: ["deckId": deck.id.uuidString, "slideCount": "\(slideCount)", "style": style],
            dataPayload: ["topic": topic, "deckTitle": deck.title]
        )
    }
}
