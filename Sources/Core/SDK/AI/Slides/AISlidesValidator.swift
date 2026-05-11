import Foundation

struct AISlidesValidator {
    private let validLayoutsByType: [String: Set<String>] = [
        "title": ["centered", "title"],
        "bullet": ["verticalList", "titleAndBody"],
        "image": ["imageCaption", "splitHStack"],
        "chart": ["chart", "splitHStack"],
        "twocolumn": ["splitHStack"],
        "two_column": ["splitHStack"]
    ]

    func validate(content: SlideContentPayload, input: SlideInput) -> SlideContentPayload {
        var sanitized = content
        print("[Validator] Validating \(content.slides.count) slides")

        if AIGenSlideCatalog.themes.first(where: { $0.id == sanitized.theme }) == nil {
            sanitized.theme = AIGenSlideCatalog.defaultThemeID
        }

        sanitized.slides = sanitized.slides
            .prefix(max(input.slideCount, 5))
            .enumerated()
            .map { offset, slide in
                var fixed = slide
                fixed.index = offset
                fixed.title = slide.title.isEmpty ? "Slide \(offset + 1)" : String(slide.title.prefix(80))

                fixed.elements = repairElements(slide.elements)

                if fixed.elements.isEmpty {
                    fixed.elements = [
                        .init(kind: "text", text: "Generated content unavailable", bullets: nil, caption: nil, chartTitle: nil, chartLabels: nil, chartValues: nil)
                    ]
                }

                let validLayouts = validLayoutsByType[slide.type.lowercased()] ?? Set(["verticalList", "titleAndBody", "centered", "splitHStack"])
                if !validLayouts.contains(slide.layout) {
                    fixed.layout = validLayouts.first ?? "verticalList"
                }

                return fixed
            }

        if sanitized.slides.count < 5 {
            print("[Validator] Padding from \(sanitized.slides.count) to 5 slides")
            while sanitized.slides.count < 5 {
                let idx = sanitized.slides.count
                sanitized.slides.append(
                    .init(index: idx, title: "Section \(idx + 1)", type: "bullet", layout: "verticalList", elements: [
                        .init(kind: "text", text: "Generated content unavailable", bullets: nil, caption: nil, chartTitle: nil, chartLabels: nil, chartValues: nil)
                    ], metadata: [:])
                )
            }
        }

        print("[Validator] Output: \(sanitized.slides.count) validated slides")
        return sanitized
    }

    private func repairElements(_ elements: [SlideContentPayload.ContentSlide.ContentElement]) -> [SlideContentPayload.ContentSlide.ContentElement] {
        elements.compactMap { element in
            var output = element
            let kind = element.kind.lowercased()

            if kind == "image", (element.text?.isEmpty ?? true), (element.caption?.isEmpty ?? true) {
                output.caption = "Image"
            }

            if let bullets = element.bullets {
                output.bullets = bullets
                    .prefix(8)
                    .map { bullet in
                        let trimmed = bullet.trimmingCharacters(in: .whitespacesAndNewlines)
                        return trimmed.isEmpty ? "Content point" : String(trimmed.prefix(120))
                    }
            }

            if let text = element.text {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                output.text = trimmed.isEmpty ? "Generated content" : trimmed
            }

            return output
        }
    }
}
