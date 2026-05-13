import Foundation

struct AISlidesStrictDecoder {
    private let decoder = AIResponseDecoder()

    func decodePlan(_ json: String) throws -> SlidePlan {
        let cleaned = stripMarkdownFences(json)
        return try decoder.decode(
            SlidePlan.self,
            from: cleaned,
            schema: .object([
                "title": .string,
                "theme": .string,
                "slides": .array(.object([
                    "index": .int,
                    "type": .string,
                    "intent": .string,
                    "layout": .string
                ]))
            ])
        )
    }

    func decodeVisuals(_ json: String) throws -> VisualPlan {
        let cleaned = stripMarkdownFences(json)
        return try decoder.decode(
            VisualPlan.self,
            from: cleaned,
            schema: .object([
                "slides": .array(.object([
                    "index": .int,
                    "requires_visual": .bool
                ]))
            ])
        )
    }

    func decodeContent(_ json: String) throws -> SlideContentPayload {
        let cleaned = stripMarkdownFences(json)
        return try decoder.decode(
            SlideContentPayload.self,
            from: cleaned,
            schema: .object([
                "title": .string,
                "theme": .string,
                "slides": .array(.object([
                    "index": .int,
                    "title": .string,
                    "type": .string,
                    "layout": .string,
                    "elements": .array(.object([
                        "kind": .string
                    ])),
                    "metadata": .object([:])
                ]))
            ])
        )
    }

    private func stripMarkdownFences(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        if let startIndex = cleaned.firstIndex(of: "{") {
            cleaned = String(cleaned[startIndex...])
        }
        if let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[...endIndex])
        }

        return cleaned
    }
}
