import Foundation

struct AISlidesPromptBuilder: Sendable {

    // MARK: - Full GenSlidesScheme prompt

    func buildFullPrompt(_ input: SlideInput) -> String {
        let context = buildContext(input)
        return """
        You are a slide generation engine.
        Your task is to generate a presentation using STRICT JSON.
        Follow this schema EXACTLY:
        GenSlidesScheme:
        {
          "meta": {
            "title": string,
            "description": string,
            "accentColor": string (HEX)
          },
          "theme": {
            "gradient": [string],
            "font": string,
            "glass": boolean,
            "contrast": string
          },
          "slides": [
            {
              "id": UUID,
              "type": "title | bullet | image | twoColumn | chart | gallery",
              "title": string,
              "layout": { "alignment": string, "spacing": number },
              "elements": [
                { "text": string } OR
                { "bullets": [string] } OR
                { "image": { "url": "", "query": string } }
              ]
            }
          ]
        }
        Rules:
        - Minimum 5 slides
        - Maximum 12 slides
        - Titles under 8 words
        - Max 6 bullets per slide
        - Max 12 words per bullet
        - Include image queries for visual slides
        - No empty elements
        - No duplicate slides
        - Use concise, professional language

        Tone: \(input.tone.rawValue)
        Audience: \(input.audience.rawValue)
        Slide count: \(input.slideCount)

        Context:
        \(context)

        Return ONLY JSON. No markdown. No explanation.
        """
    }

    private func buildContext(_ input: SlideInput) -> String {
        var parts: [String] = []

        if !input.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Topics: \(input.rawText)")
        }
        if !input.notes.isEmpty {
            parts.append("Key points: \(input.notes.joined(separator: "; "))")
        }
        if !input.sections.isEmpty {
            let sectionDesc = input.sections.map { "\($0.title): \($0.summary)" }.joined(separator: "\n")
            parts.append("Sections:\n\(sectionDesc)")
        }
        if !input.whiteboardNodes.isEmpty {
            let nodeSummary = input.whiteboardNodes.map { "[\($0.type.rawValue)] \($0.title): \($0.content)" }.joined(separator: "\n")
            parts.append("Whiteboard nodes:\n\(nodeSummary)")
        }
        if !input.documents.isEmpty {
            parts.append("Documents:\n\(input.documents.joined(separator: "\n"))")
        }

        return parts.isEmpty ? "General presentation" : parts.joined(separator: "\n\n")
    }

    // MARK: - Multi-stage prompts (legacy pipeline)

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
