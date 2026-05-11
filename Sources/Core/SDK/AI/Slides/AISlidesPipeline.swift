import Foundation

public enum AISlidesPipelineError: LocalizedError {
    case providerFailure(code: Int, message: String)
    case schemaValidationFailed(violations: [String])
    case emptyProviderResponse
    case contextExtractionFailed(reason: String)
    case decodingRejected(stage: String, rawLength: Int, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .providerFailure(let code, let message):
            return "AI provider error [\(code)]: \(message)"
        case .schemaValidationFailed(let violations):
            return "Schema validation failed: \(violations.joined(separator: "; "))"
        case .emptyProviderResponse:
            return "AI provider returned an empty response"
        case .contextExtractionFailed(let reason):
            return "Context extraction failed: \(reason)"
        case .decodingRejected(let stage, let rawLength, let underlying):
            return "Decoding rejected at \(stage) (\(rawLength) chars): \(underlying.localizedDescription)"
        }
    }
}

@MainActor
struct AISlidesPipeline {
    private let promptBuilder = AISlidesPromptBuilder()
    private let decoder = AISlidesStrictDecoder()
    private let mapper = AISlidesRendererMapper()
    private let imageService = AISlidesImageService()
    private let cache = AISlidesCache.shared
    private let themeEngine = AISlidesThemeEngine()
    private let assetResolver = AISlidesAssetResolver()
    private let schemaEnforcer = AISlidesSchemaEnforcer()

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async throws -> SlideDeck {
        progress("Extracting context", 0.1)
        let context = try extractContext(input: input)

        progress("Generating slide plan", 0.24)
        let plan = try await generateSlidePlan(context: context, input: input)

        progress("Enriching visuals", 0.38)
        let visuals = try await enrichWithVisuals(plan: plan, context: context, input: input)

        progress("Generating content", 0.55)
        let content = try await generateContent(plan: plan, visuals: visuals, context: context, input: input)

        progress("Validating schema", 0.70)
        let validated = try schemaEnforcer.enforce(content: content, input: input)

        progress("Resolving assets", 0.84)
        let resolved = await resolveAssets(content: validated, visuals: visuals, input: input)
        let draftDeck = try buildDraftDeck(content: resolved, visuals: visuals, input: input)
        let preloadedDeck = await assetResolver.resolveAssets(for: draftDeck)

        progress("Finalizing deck", 0.95)
        let deck = finalizeDeck(deck: preloadedDeck, input: input)

        progress("Complete", 1.0)
        return deck
    }

    func extractContext(input: SlideInput) throws -> String {
        let whiteboardSummary = input.sections.map { "\($0.title): \($0.summary)" }.joined(separator: "\n")
        let nodesSummary = input.whiteboardNodes.map { "[\($0.type.rawValue)] \($0.title): \($0.content)" }.joined(separator: "\n")
        let notesSummary = input.notes.joined(separator: "\n")
        let docsSummary = input.documents.joined(separator: "\n")
        let imageSummary = input.uploadedImages.map(\.fileName).joined(separator: ", ")

        let context = [input.rawText, notesSummary, whiteboardSummary, nodesSummary, docsSummary, imageSummary]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")

        guard !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AISlidesPipelineError.contextExtractionFailed(reason: "All input fields are empty")
        }

        return context
    }

    func generateSlidePlan(context: String, input: SlideInput) async throws -> SlidePlan {
        let prompt = promptBuilder.planningPrompt(context: context, input: input)
        let key = "plan_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await requestProviderJSON(
                prompt: prompt,
                schema: Self.planningSchema,
                model: "openrouter/reasoning",
                stage: "planning"
            )
            await cache.storeJSON(json, for: key)
        }
        return try strictDecodePlan(json)
    }

    func enrichWithVisuals(plan: SlidePlan, context: String, input: SlideInput) async throws -> VisualPlan {
        let prompt = promptBuilder.visualPrompt(plan: plan, context: context, includeImages: input.includeImages)
        let key = "visuals_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await requestProviderJSON(
                prompt: prompt,
                schema: Self.visualSchema,
                model: "openrouter/vision",
                stage: "visuals"
            )
            await cache.storeJSON(json, for: key)
        }
        return try strictDecodeVisuals(json)
    }

    func generateContent(plan: SlidePlan, visuals: VisualPlan, context: String, input: SlideInput) async throws -> SlideContentPayload {
        let prompt = promptBuilder.contentPrompt(plan: plan, visuals: visuals, context: context, input: input)
        let key = "content_\(AISlidesCache.hash(prompt))"
        let json: String
        if let cached = await cache.cachedJSON(for: key) {
            json = cached
        } else {
            json = try await requestProviderJSON(
                prompt: prompt,
                schema: Self.contentSchema,
                model: "openrouter/language",
                stage: "content"
            )
            await cache.storeJSON(json, for: key)
        }
        return try strictDecodeContent(json)
    }

    private func requestProviderJSON(prompt: String, schema: String, model: String, stage: String) async throws -> String {
        let json: String
        do {
            json = try await AIService.shared.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: schema,
                preferredModel: model,
                systemPrompt: "Return strict JSON only. No markdown."
            )
        } catch {
            let nsError = error as NSError
            throw AISlidesPipelineError.providerFailure(
                code: nsError.code,
                message: nsError.localizedDescription
            )
        }

        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AISlidesPipelineError.emptyProviderResponse
        }

        return json
    }

    private func strictDecodePlan(_ json: String) throws -> SlidePlan {
        do {
            return try decoder.decodePlan(json)
        } catch {
            throw AISlidesPipelineError.decodingRejected(
                stage: "planning",
                rawLength: json.count,
                underlying: error
            )
        }
    }

    private func strictDecodeVisuals(_ json: String) throws -> VisualPlan {
        do {
            return try decoder.decodeVisuals(json)
        } catch {
            throw AISlidesPipelineError.decodingRejected(
                stage: "visuals",
                rawLength: json.count,
                underlying: error
            )
        }
    }

    private func strictDecodeContent(_ json: String) throws -> SlideContentPayload {
        do {
            return try decoder.decodeContent(json)
        } catch {
            throw AISlidesPipelineError.decodingRejected(
                stage: "content",
                rawLength: json.count,
                underlying: error
            )
        }
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

    private func buildDraftDeck(content: SlideContentPayload, visuals: VisualPlan, input: SlideInput) throws -> SlideDeck {
        let slides = content.slides.map { slide -> Slide in
            Slide(
                type: slide.type,
                title: slide.title,
                layout: mapper.mapLayout(for: slide.type),
                elements: mapper.mapElements(slide.elements, visuals: visuals.slides.first(where: { $0.index == slide.index })),
                metadata: slide.metadata
            )
        }

        guard !slides.isEmpty else {
            throw AISlidesPipelineError.schemaValidationFailed(violations: ["Provider returned zero slides"])
        }

        var deck = SlideDeck(
            title: content.title,
            theme: content.theme,
            slides: slides,
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
            copy.backgroundColorHex = themeSelection.theme.gradient.first?.replacingOccurrences(of: "#", with: "") ?? "0F172A"
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
