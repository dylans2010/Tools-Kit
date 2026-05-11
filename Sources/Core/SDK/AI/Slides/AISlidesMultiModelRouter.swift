import Foundation

protocol AISlidesModelRouter {
    func plan(_ input: SlideInput) async throws -> SlidePlan
    func generateContent(_ plan: SlidePlan) async throws -> SlideDeck
    func optimize(_ deck: SlideDeck) async throws -> SlideDeck
}

struct AISlidesMultiModelRouter: AISlidesModelRouter {
    private let promptBuilder = AISlidesPromptBuilder()
    private let decoder = AISlidesDecoder()

    func plan(_ input: SlideInput) async throws -> SlidePlan {
        let context = [input.rawText, input.notes.joined(separator: "\n"), input.documents.joined(separator: "\n")]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")

        let json = try await AIService.shared.generateStructuredJSON(
            prompt: promptBuilder.planningPrompt(context: context, input: input),
            jsonSchema: AISlidesPipeline.planningSchema,
            preferredModel: "openrouter/reasoning",
            systemPrompt: "Return strict JSON only. Deterministic structure."
        )
        return try decoder.decodePlan(json)
    }

    func generateContent(_ plan: SlidePlan) async throws -> SlideDeck {
        let slides = plan.slides.map { planned in
            Slide(type: planned.type, title: planned.intent, layout: planned.layout, elements: [SlideElement(kind: .text)], metadata: ["source": "router.generateContent"])
        }
        return SlideDeck(title: plan.title, theme: plan.theme, slides: slides, createdAt: Date(), updatedAt: Date())
    }

    func optimize(_ deck: SlideDeck) async throws -> SlideDeck {
        var optimized = deck
        optimized.updatedAt = Date()
        optimized.slides = optimized.slides.map { slide in
            var copy = slide
            if copy.elements.isEmpty {
                copy.elements = [SlideElement(kind: .text)]
            }
            return copy
        }
        return optimized
    }
}
