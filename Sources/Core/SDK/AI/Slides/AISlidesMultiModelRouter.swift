import Foundation

protocol AISlidesModelRouter {
    func plan(_ input: SlideInput) async throws -> SlidePlan
    func generateContent(_ plan: SlidePlan) async throws -> SlideDeck
}

struct AISlidesMultiModelRouter: AISlidesModelRouter {
    private let promptBuilder = AISlidesPromptBuilder()
    private let decoder = AISlidesStrictDecoder()
    private let modelConfig = ModelConfigManager.shared

    func plan(_ input: SlideInput) async throws -> SlidePlan {
        let context = [input.rawText, input.notes.joined(separator: "\n"), input.documents.joined(separator: "\n")]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")

        let prompt = promptBuilder.planningPrompt(context: context, input: input)
        let json = try await AIService.shared.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: AISlidesPipeline.planningSchema,
            preferredModel: modelConfig.effectiveReasoningModel(),
            systemPrompt: "Return strict JSON only. Deterministic structure."
        )

        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AISlidesPipelineError.emptyProviderResponse
        }

        return try decoder.decodePlan(json)
    }

    func generateContent(_ plan: SlidePlan) async throws -> SlideDeck {
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
            preferredModel: modelConfig.effectiveLanguageModel(),
            systemPrompt: "Return strict JSON only."
        )

        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AISlidesPipelineError.emptyProviderResponse
        }

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
                        el.text = element.text ?? ""
                    }
                    return el
                },
                metadata: contentSlide.metadata
            )
        }

        guard !slides.isEmpty else {
            throw AISlidesPipelineError.schemaValidationFailed(violations: ["Provider returned zero slides"])
        }

        return SlideDeck(
            title: content.title,
            theme: content.theme,
            slides: slides,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
