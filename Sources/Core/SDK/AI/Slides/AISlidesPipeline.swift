import Foundation

@MainActor
struct AISlidesPipeline {
    private let promptBuilder = AISlidesPromptBuilder()
    private let decoder = AISlidesDecoder()
    private let validator = AISlidesValidator()
    private let mapper = AISlidesRendererMapper()
    private let imageService = AISlidesImageService()
    private let cache = AISlidesCache.shared

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async -> SlideDeck {
        do {
            progress("Extracting context", 0.1)
            let context = try await extractContext(input: input)

            progress("Generating plan", 0.25)
            let plan = try await generateSlidePlan(context: context, input: input)

            progress("Adding visuals", 0.4)
            let visuals = try await enrichWithVisuals(plan: plan, context: context, input: input)

            progress("Generating content", 0.6)
            let content = try await generateContent(plan: plan, visuals: visuals, context: context, input: input)

            progress("Validating", 0.75)
            let validated = validate(content: content)

            progress("Resolving assets", 0.9)
            let resolved = await resolveAssets(content: validated, visuals: visuals)

            progress("Building deck", 1.0)
            return buildSlideDeck(content: resolved, visuals: visuals)
        } catch {
            return fallbackDeck(from: input)
        }
    }

    func extractContext(input: SlideInput) async throws -> String {
        let whiteboardSummary = input.sections.map { "\($0.title): \($0.summary)" }.joined(separator: "\n")
        let nodesSummary = input.whiteboardNodes.map { "[\($0.type.rawValue)] \($0.title): \($0.content)" }.joined(separator: "\n")
        let notesSummary = input.notes.joined(separator: "\n")
        let docsSummary = input.documents.joined(separator: "\n")

        return [input.rawText, notesSummary, whiteboardSummary, nodesSummary, docsSummary]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
    }

    func generateSlidePlan(context: String, input: SlideInput) async throws -> SlidePlan {
        let prompt = promptBuilder.planningPrompt(context: context, input: input)
        let key = "plan_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await AIService.shared.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: planningSchema,
                preferredModel: "openrouter/free",
                systemPrompt: "Return strict JSON only. No markdown. No prose."
            )
            await cache.storeJSON(json, for: key)
        }
        return try decoder.decodePlan(json)
    }

    func enrichWithVisuals(plan: SlidePlan, context: String, input: SlideInput) async throws -> VisualPlan {
        let prompt = promptBuilder.visualPrompt(plan: plan, context: context, includeImages: input.includeImages)
        let key = "visuals_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await AIService.shared.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: visualSchema,
                preferredModel: "openrouter/free",
                systemPrompt: "Return strict JSON only."
            )
            await cache.storeJSON(json, for: key)
        }
        return try decoder.decodeVisuals(json)
    }

    func generateContent(plan: SlidePlan, visuals: VisualPlan, context: String, input: SlideInput) async throws -> SlideContentPayload {
        let prompt = promptBuilder.contentPrompt(plan: plan, visuals: visuals, context: context, input: input)
        let key = "content_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await AIService.shared.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: contentSchema,
                preferredModel: "openrouter/free",
                systemPrompt: "Return strict JSON only."
            )
            await cache.storeJSON(json, for: key)
        }
        return try decoder.decodeContent(json)
    }

    func validate(content: SlideContentPayload) -> SlideContentPayload {
        validator.validate(content)
    }

    func resolveAssets(content: SlideContentPayload, visuals: VisualPlan) async -> SlideContentPayload {
        var resolved = content

        for slideIndex in resolved.slides.indices {
            guard let visual = visuals.slides.first(where: { $0.index == resolved.slides[slideIndex].index }) else { continue }
            guard visual.requiresVisual, let query = visual.imageQuery else { continue }

            let imageURL = await imageService.resolveImage(for: query)
            guard let imageURL else { continue }

            let hasImage = resolved.slides[slideIndex].elements.contains { $0.kind.lowercased() == "image" }
            if !hasImage {
                var element = SlideContentPayload.ContentSlide.ContentElement(kind: "image", text: nil, bullets: nil, caption: query, chartTitle: nil, chartLabels: nil, chartValues: nil)
                element.text = imageURL.absoluteString
                resolved.slides[slideIndex].elements.append(element)
            }
        }

        return resolved
    }

    func buildSlideDeck(content: SlideContentPayload, visuals: VisualPlan) -> SlideDeck {
        let slides = content.slides.map { slide -> Slide in
            var model = Slide(
                type: slide.type,
                title: slide.title,
                layout: mapper.mapLayout(for: slide.type),
                elements: mapper.mapElements(slide.elements, visuals: visuals.slides.first(where: { $0.index == slide.index })),
                metadata: slide.metadata
            )
            model.backgroundColorHex = "0F172A"
            return model
        }

        return SlideDeck(
            title: content.title,
            theme: content.theme,
            slides: slides.isEmpty ? [bulletFallbackSlide(title: content.title)] : slides,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func fallbackDeck(from input: SlideInput) -> SlideDeck {
        var deck = SlideDeck(title: input.rawText.isEmpty ? "AI Slides" : input.rawText)
        deck.theme = "fallback"
        deck.slides = [bulletFallbackSlide(title: deck.title)]
        return deck
    }

    private func bulletFallbackSlide(title: String) -> Slide {
        var bullets = SlideElement(kind: .bullets)
        bullets.bullets = [
            "Goal: \(String(title.split(separator: " ").prefix(6).joined(separator: " ")))",
            "AI fallback mode enabled",
            "Review source notes and whiteboards"
        ]
        return Slide(type: "bullet", title: "Overview", layout: "verticalList", elements: [bullets], metadata: ["fallback": "true"])
    }

    private var planningSchema: String {
        """
        {
          "type": "object",
          "required": ["title", "theme", "slides"],
          "properties": {
            "title": { "type": "string" },
            "theme": { "type": "string" },
            "slides": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["index", "type", "intent", "layout"],
                "properties": {
                  "index": { "type": "integer" },
                  "type": { "type": "string" },
                  "intent": { "type": "string" },
                  "layout": { "type": "string" }
                }
              }
            }
          }
        }
        """
    }

    private var visualSchema: String {
        """
        {
          "type": "object",
          "required": ["slides"],
          "properties": {
            "slides": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["index", "requires_visual"],
                "properties": {
                  "index": { "type": "integer" },
                  "requires_visual": { "type": "boolean" },
                  "image_query": { "type": ["string", "null"] },
                  "chart_spec": { "type": ["string", "null"] }
                }
              }
            }
          }
        }
        """
    }

    private var contentSchema: String {
        """
        {
          "type": "object",
          "required": ["title", "theme", "slides"],
          "properties": {
            "title": { "type": "string" },
            "theme": { "type": "string" },
            "slides": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["index", "title", "type", "layout", "elements", "metadata"],
                "properties": {
                  "index": { "type": "integer" },
                  "title": { "type": "string" },
                  "type": { "type": "string" },
                  "layout": { "type": "string" },
                  "elements": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "required": ["kind"],
                      "properties": {
                        "kind": { "type": "string" },
                        "text": { "type": ["string", "null"] },
                        "bullets": { "type": ["array", "null"], "items": { "type": "string" } },
                        "caption": { "type": ["string", "null"] },
                        "chart_title": { "type": ["string", "null"] },
                        "chart_labels": { "type": ["array", "null"], "items": { "type": "string" } },
                        "chart_values": { "type": ["array", "null"], "items": { "type": "number" } }
                      }
                    }
                  },
                  "metadata": {
                    "type": "object",
                    "additionalProperties": { "type": "string" }
                  }
                }
              }
            }
          }
        }
        """
    }
}
