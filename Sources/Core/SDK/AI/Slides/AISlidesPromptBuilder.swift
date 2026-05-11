import Foundation

struct AISlidesPromptBuilder {
    func planningPrompt(context: String, input: SlideInput) -> String {
        """
        Build only a slide plan as strict JSON.
        No slide body text, no markdown, no prose.
        Provide exactly \(input.slideCount) slides.
        Include `type`, `intent`, and `layout` for each slide.

        Tone: \(input.tone.rawValue)
        Audience: \(input.audience.rawValue)
        Visual density: \(input.visualDensity.rawValue)
        Preferred theme: \(input.preferredThemeID ?? "auto")
        Preferred style: \(input.preferredStyleID ?? "auto")

        Context:
        \(context)
        """
    }

    func visualPrompt(plan: SlidePlan, context: String, includeImages: Bool) -> String {
        """
        Enrich the slide plan with visuals as strict JSON.
        For each slide output `requires_visual` and either `image_query` or `chart_spec`.
        includeImages: \(includeImages)

        Slide plan:
        \(encode(plan))

        Context:
        \(context)
        """
    }

    func contentPrompt(plan: SlidePlan, visuals: VisualPlan, context: String, input: SlideInput) -> String {
        """
        Generate slide content only as strict JSON.
        Rules:
        - max 6 bullets per slide
        - max 12 words per bullet
        - titles max 8 words
        - avoid repetition

        Tone: \(input.tone.rawValue)
        Audience: \(input.audience.rawValue)

        Plan:
        \(encode(plan))

        Visuals:
        \(encode(visuals))

        Context:
        \(context)
        """
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }
}
