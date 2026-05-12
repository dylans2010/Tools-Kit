import Foundation
import Combine

final class SlideDecksManager: ObservableObject {
    nonisolated(unsafe) static let shared = SlideDecksManager()

    @Published var decks: [SlideDeck] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Slides", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func deckURL(for id: UUID) -> URL {
        saveDir.appendingPathComponent("\(id.uuidString).json")
    }

    private init() {
        load()
    }

    // MARK: - CRUD

    @discardableResult
    func createDeck(title: String = "Untitled Deck") -> SlideDeck {
        let deck = SlideDeck.empty(title: title)
        decks.insert(deck, at: 0)
        save(deck)
        return deck
    }

    func updateDeck(_ deck: SlideDeck) {
        if let idx = decks.firstIndex(where: { $0.id == deck.id }) {
            var updated = deck
            updated.updatedAt = Date()
            decks[idx] = updated
            save(updated)
        }
    }

    func deleteDeck(_ deck: SlideDeck) {
        decks.removeAll { $0.id == deck.id }
        try? FileManager.default.removeItem(at: deckURL(for: deck.id))
    }

    func addDeck(_ deck: SlideDeck) {
        decks.insert(deck, at: 0)
        save(deck)
    }

    // MARK: - Persistence

    private func save(_ deck: SlideDeck) {
        do {
            let data = try JSONEncoder().encode(deck)
            try data.write(to: deckURL(for: deck.id))
        } catch {
            print("SlideDecksManager: save error \(error)")
        }
    }

    private func load() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: saveDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        decks = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> SlideDeck? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SlideDeck.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - AI Deck Generation

    struct AIDeckElement: Codable, Sendable {
        let kind: String
        let text: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let fontSize: Double
        let textColor: String
        let fillColor: String
    }

    struct AIDeckSlide: Codable, Sendable {
        let title: String
        let background: String
        let elements: [AIDeckElement]
    }

    struct AIDeckPayload: Codable, Sendable {
        let title: String
        let slides: [AIDeckSlide]
        let speakerNotes: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["title", "slides", "speakerNotes"],
          "properties": {
            "title": { "type": "string" },
            "speakerNotes": { "type": "array", "items": { "type": "string" } },
            "slides": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "background", "elements"],
                "properties": {
                  "title": { "type": "string" },
                  "background": { "type": "string" },
                  "elements": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "required": ["kind", "text", "x", "y", "width", "height", "fontSize", "textColor", "fillColor"],
                      "properties": {
                        "kind": { "type": "string" },
                        "text": { "type": "string" },
                        "x": { "type": "number" },
                        "y": { "type": "number" },
                        "width": { "type": "number" },
                        "height": { "type": "number" },
                        "fontSize": { "type": "number" },
                        "textColor": { "type": "string" },
                        "fillColor": { "type": "string" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "title": .string,
            "slides": .array(.object([
                "title": .string,
                "background": .string,
                "elements": .array(.object([
                    "kind": .string,
                    "text": .string,
                    "x": .double,
                    "y": .double,
                    "width": .double,
                    "height": .double,
                    "fontSize": .double,
                    "textColor": .string,
                    "fillColor": .string
                ]))
            ])),
            "speakerNotes": .array(.string)
        ])
    }

    @MainActor
    func generateDeckFromPrompt(_ prompt: String) async throws -> AIDeckPayload {
        // Generate full presentation structure using strict schema validation.
        let request = """
        Build a complete deck from this prompt. Accept natural language, infer missing details like audience/structure/slide count when absent, and keep the structure polished:
        \(prompt)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: request,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a presentation designer that can interpret vague natural language. Infer missing details safely. Return strict JSON only."
        )
        return try aiDecoder.decode(AIDeckPayload.self, from: json, schema: aiSchema)
    }
}
