import Foundation

struct AISlidesDecoder: Sendable {
    private let decoder = AIResponseDecoder()

    func decodePlan(_ json: String) throws -> SlidePlan {
        try decoder.decode(
            SlidePlan.self,
            from: json,
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
        try decoder.decode(
            VisualPlan.self,
            from: json,
            schema: .object([
                "slides": .array(.object([
                    "index": .int,
                    "requires_visual": .bool
                ]))
            ])
        )
    }

    func decodeContent(_ json: String) throws -> SlideContentPayload {
        try decoder.decode(
            SlideContentPayload.self,
            from: json,
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
}
