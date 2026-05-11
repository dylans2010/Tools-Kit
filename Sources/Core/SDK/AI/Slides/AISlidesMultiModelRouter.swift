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
        print("[MultiModelRouter] plan: building prompt")
        let context = [input.rawText, input.notes.joined(separator: "\n"), input.documents.joined(separator: "\n")]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")

        let prompt = promptBuilder.planningPrompt(context: context, input: input)
        print("[MultiModelRouter] plan: calling generateJSON")
        let json = try await AIService.shared.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: AISlidesPipeline.planningSchema,
            preferredModel: "openrouter/reasoning",
            systemPrompt: "Return strict JSON only. Deterministic structure."
        )
        print("[MultiModelRouter] plan: decoding response (\(json.count) chars)")
        return try decoder.decodePlan(json)
    }

    func generateContent(_ plan: SlidePlan) async throws -> SlideDeck {
        print("[MultiModelRouter] generateContent: building slides from plan")
        let prompt = """
        Generate detailed slide content for the following plan:
        Title: \(plan.title)
        Theme: \(plan.theme)
        Slides: \(plan.slides.map { "[\($0.type)] \($0.intent)" }.joined(separator: ", "))
        
        Return a JSON object with title, theme, and slides array.
        """

        let json = try await AIService.shared.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: AISlidesPipeline.contentSchema,
            preferredModel: "openrouter/language",
            systemPrompt: "Return strict JSON only."
        )
        print("[MultiModelRouter] generateContent: received response (\(json.count) chars)")

        let content = try decoder.decodeContent(json)
        let slides = content.slides.map { contentSlide in
            Slide(
                type: contentSlide.type,
                title: contentSlide.title,
                layout: contentSlide.layout,
                elements: contentSlide.elements.map { element in
                    var el: SlideElement
                    switch element.kind.lowercased() {
                    case "bullets":
                        el = SlideElement(kind: .bullets)
                        el.bullets = element.bullets ?? []
                    case "image":
                        el = SlideElement(kind: .image)
                        if let url = element.text { el.imageURL = URL(string: url) }
                        el.caption = element.caption ?? ""
                    case "chart":
                        el = SlideElement(kind: .chart)
                        el.chartData = SlideElement.ChartData(
                            title: element.chartTitle ?? "",
                            labels: element.chartLabels ?? [],
                            values: element.chartValues ?? []
                        )
                    default:
                        el = SlideElement(kind: .text)
                        el.text = element.text ?? "Content"
                    }
                    return el
                },
                metadata: contentSlide.metadata
            )
        }

        return SlideDeck(
            title: content.title,
            theme: content.theme,
            slides: slides,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func optimize(_ deck: SlideDeck) async throws -> SlideDeck {
        print("[MultiModelRouter] optimize: refining \(deck.slides.count) slides")
        var optimized = deck
        optimized.updatedAt = Date()
        optimized.slides = optimized.slides.map { slide in
            var copy = slide
            if copy.elements.isEmpty {
                var el = SlideElement(kind: .text)
                el.text = "Generated content unavailable"
                copy.elements = [el]
            }
            return copy
        }
        print("[MultiModelRouter] optimize: complete")
        return optimized
    }
}
