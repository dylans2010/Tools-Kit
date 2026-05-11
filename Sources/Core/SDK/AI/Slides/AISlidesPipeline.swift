import Foundation

@MainActor
struct AISlidesPipeline {
    private let defaultBackgroundHex = "0F172A"
    private let promptBuilder = AISlidesPromptBuilder()
    private let decoder = AISlidesDecoder()
    private let validator = AISlidesValidator()
    private let mapper = AISlidesRendererMapper()
    private let imageService = AISlidesImageService()
    private let cache = AISlidesCache.shared
    private let router: AISlidesModelRouter = AISlidesMultiModelRouter()
    private let themeEngine = AISlidesThemeEngine()
    private let assetResolver = AISlidesAssetResolver()

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async throws -> SlideDeck {
        print("[SlidesPipeline] Step: Context Extraction")
        progress("Extracting context", 0.1)
        let context = try await extractContext(input: input)
        print("[SlidesPipeline] Context extracted (\(context.count) chars)")

        print("[SlidesPipeline] Step: Planning")
        progress("Generating slide plan", 0.24)
        let plan = try await generateSlidePlan(context: context, input: input)
        print("[SlidesPipeline] Plan generated: \(plan.slides.count) planned slides")

        print("[SlidesPipeline] Step: Visual Enrichment")
        progress("Enriching visuals", 0.38)
        let visuals = try await enrichWithVisuals(plan: plan, context: context, input: input)
        print("[SlidesPipeline] Visuals enriched: \(visuals.slides.count) visual specs")

        print("[SlidesPipeline] Step: Content Generation")
        progress("Generating content", 0.55)
        let content = try await generateContent(plan: plan, visuals: visuals, context: context, input: input)
        print("[SlidesPipeline] Content generated: \(content.slides.count) content slides")

        print("[SlidesPipeline] Step: Validation")
        progress("Validating output", 0.70)
        let validated = validator.validate(content: content, input: input)
        print("[SlidesPipeline] Validated: \(validated.slides.count) slides passed")

        print("[SlidesPipeline] Step: Asset Resolution")
        progress("Resolving assets", 0.84)
        let resolved = await resolveAssets(content: validated, visuals: visuals, input: input)
        let draftDeck = buildDraftDeck(content: resolved, visuals: visuals, input: input)
        let preloadedDeck = await assetResolver.resolveAssets(for: draftDeck)
        print("[SlidesPipeline] Assets resolved for \(preloadedDeck.slides.count) slides")

        print("[SlidesPipeline] Step: Finalization")
        progress("Finalizing deck", 0.95)
        let deck = finalizeDeck(deck: preloadedDeck, input: input)

        print("[SlidesPipeline] Step: Optimization")
        progress("Optimizing", 1.0)
        let optimized = (try? await router.optimize(deck)) ?? deck
        print("[SlidesPipeline] Complete: \(optimized.slides.count) final slides")
        return optimized
    }

    func extractContext(input: SlideInput) async throws -> String {
        let whiteboardSummary = input.sections.map { "\($0.title): \($0.summary)" }.joined(separator: "\n")
        let nodesSummary = input.whiteboardNodes.map { "[\($0.type.rawValue)] \($0.title): \($0.content)" }.joined(separator: "\n")
        let notesSummary = input.notes.joined(separator: "\n")
        let docsSummary = input.documents.joined(separator: "\n")
        let imageSummary = input.uploadedImages.map(\.fileName).joined(separator: ", ")

        return [input.rawText, notesSummary, whiteboardSummary, nodesSummary, docsSummary, imageSummary]
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
                jsonSchema: Self.planningSchema,
                preferredModel: "openrouter/reasoning",
                systemPrompt: "Return strict JSON only. No markdown."
            )
            await cache.storeJSON(json, for: key)
        }

        do {
            return try decoder.decodePlan(json)
        } catch {
            print("AISlidesPipeline decodePlan fallback: \(error)")
            return try await router.plan(input)
        }
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
                jsonSchema: Self.visualSchema,
                preferredModel: "openrouter/vision",
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
                jsonSchema: Self.contentSchema,
                preferredModel: "openrouter/language",
                systemPrompt: "Return strict JSON only."
            )
            await cache.storeJSON(json, for: key)
        }
        return try decoder.decodeContent(json)
    }

    func resolveAssets(content: SlideContentPayload, visuals: VisualPlan, input: SlideInput) async -> SlideContentPayload {
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

        for (idx, image) in input.uploadedImages.enumerated() where idx < resolved.slides.count {
            var element = SlideContentPayload.ContentSlide.ContentElement(kind: "image", text: nil, bullets: nil, caption: image.fileName, chartTitle: nil, chartLabels: nil, chartValues: nil)
            element.text = "upload://\(image.fileName)"
            resolved.slides[idx].elements.insert(element, at: 0)
        }

        return resolved
    }

    private func buildDraftDeck(content: SlideContentPayload, visuals: VisualPlan, input: SlideInput) -> SlideDeck {
        let slides = content.slides.map { slide -> Slide in
            var model = Slide(
                type: slide.type,
                title: slide.title,
                layout: mapper.mapLayout(for: slide.type),
                elements: mapper.mapElements(slide.elements, visuals: visuals.slides.first(where: { $0.index == slide.index })),
                metadata: slide.metadata
            )
            model.backgroundColorHex = defaultBackgroundHex
            return model
        }

        var deck = SlideDeck(
            title: content.title,
            theme: content.theme,
            slides: slides.isEmpty ? [Slide.blank(title: "Overview")] : slides,
            createdAt: Date(),
            updatedAt: Date()
        )

        for (idx, image) in input.uploadedImages.enumerated() where idx < deck.slides.count {
            if let data = Data(base64Encoded: image.dataBase64) {
                deck.slides[idx].backgroundImageData = data
            }
        }

        return deck
    }

    func finalizeDeck(deck: SlideDeck, input: SlideInput) -> SlideDeck {
        let themeSelection = themeEngine.resolveSelection(input: input, isThemeScopeEnabled: WorkspaceSDKAI().isThemeScopeEnabled)
        var themed = deck.withTheme(themeSelection.theme, style: themeSelection.style)
        themed.theme = themeSelection.theme.id
        themed.slides = themed.slides.map { slide in
            var copy = slide
            copy.backgroundColorHex = themeSelection.theme.gradient.first?.replacingOccurrences(of: "#", with: "") ?? defaultBackgroundHex
            return copy
        }
        return themed
    }

    static let planningSchema = """
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

    static let visualSchema = """
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

    static let contentSchema = """
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
