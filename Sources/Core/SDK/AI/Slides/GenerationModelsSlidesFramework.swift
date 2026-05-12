import Foundation

struct GenerationModelsSlidesFramework: Sendable {
    let aiService: AIService
    private let promptBuilder = AISlidesPromptBuilder()
    private let schemeDecoder = AISlidesSchemeDecoder()
    private let validator = AISlidesSchemeValidator()
    private let assetResolver = AISlidesAssetResolver()
    private let imageService = AISlidesImageService()

    private let modelConfig = ModelConfigManager.shared

    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    @MainActor
    func generateSlides(input: SlideInput) async throws -> GenSlidesScheme {
        let prompt = promptBuilder.buildFullPrompt(input)
        let rawJSON = try await aiService.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: Self.genSlidesSchema,
            preferredModel: modelConfig.effectiveReasoningModel(),
            systemPrompt: "You are a slide generation engine. Return ONLY JSON. No markdown. No explanation."
        )
        let decoded = try schemeDecoder.decode(rawJSON)
        let validated = try validator.validate(decoded)
        let hydrated = try await resolveImages(validated)
        return hydrated
    }

    private func resolveImages(_ scheme: GenSlidesScheme) async throws -> GenSlidesScheme {
        var resolved = scheme
        for slideIdx in resolved.slides.indices {
            for elemIdx in resolved.slides[slideIdx].elements.indices {
                if case .image(var ref) = resolved.slides[slideIdx].elements[elemIdx], ref.url.isEmpty {
                    if let url = await imageService.resolveImage(for: ref.query) {
                        ref.url = url.absoluteString
                        resolved.slides[slideIdx].elements[elemIdx] = .image(ref)
                    }
                }
            }
        }
        return resolved
    }

    static let genSlidesSchema = """
    {
      "type": "object",
      "required": ["meta", "theme", "slides"],
      "properties": {
        "meta": {
          "type": "object",
          "required": ["title", "description", "accentColor"],
          "properties": {
            "title": { "type": "string" },
            "description": { "type": "string" },
            "accentColor": { "type": "string" }
          }
        },
        "theme": {
          "type": "object",
          "required": ["gradient", "font", "glass", "contrast"],
          "properties": {
            "gradient": { "type": "array", "items": { "type": "string" } },
            "font": { "type": "string" },
            "glass": { "type": "boolean" },
            "contrast": { "type": "string" }
          }
        },
        "slides": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["id", "type", "title", "layout", "elements"],
            "properties": {
              "id": { "type": "string" },
              "type": { "type": "string", "enum": ["title", "bullet", "image", "twoColumn", "chart", "gallery"] },
              "title": { "type": "string" },
              "layout": {
                "type": "object",
                "required": ["alignment", "spacing"],
                "properties": {
                  "alignment": { "type": "string" },
                  "spacing": { "type": "number" }
                }
              },
              "elements": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "text": { "type": "string" },
                    "bullets": { "type": "array", "items": { "type": "string" } },
                    "image": {
                      "type": "object",
                      "properties": {
                        "url": { "type": "string" },
                        "query": { "type": "string" }
                      }
                    }
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
