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
        if AIGenSlideCatalog.themes.first(where: { $0.id == sanitized.theme }) == nil {
            sanitized.theme = AIGenSlideCatalog.defaultThemeID
        }

        sanitized.slides = sanitized.slides
            .prefix(input.slideCount)
            .enumerated()
            .map { offset, slide in
                var fixed = slide
                fixed.index = offset
                fixed.title = String(slide.title.split(separator: " ").prefix(8).joined(separator: " "))
                fixed.elements = normalizedElements(slide.elements)

                if fixed.elements.isEmpty {
                    fixed.elements = [
                        .init(kind: "text", text: "Summary", bullets: nil, caption: nil, chartTitle: nil, chartLabels: nil, chartValues: nil)
                    ]
                }

                let validLayouts = validLayoutsByType[slide.type.lowercased()] ?? ["verticalList"]
                if !validLayouts.contains(slide.layout) {
                    fixed.layout = validLayouts.first ?? "verticalList"
                }

                return fixed
            }

        if sanitized.slides.isEmpty {
            sanitized.slides = [
                .init(index: 0, title: "Overview", type: "bullet", layout: "verticalList", elements: [
                    .init(kind: "bullets", text: nil, bullets: ["No content generated", "Fallback slide added"], caption: nil, chartTitle: nil, chartLabels: nil, chartValues: nil)
                ], metadata: [:])
            ]
        }

        return sanitized
    }

    private func normalizedElements(_ elements: [SlideContentPayload.ContentSlide.ContentElement]) -> [SlideContentPayload.ContentSlide.ContentElement] {
        elements.compactMap { element in
            var output = element
            let kind = element.kind.lowercased()
            if kind == "image", (element.text?.isEmpty ?? true), (element.caption?.isEmpty ?? true) {
                output.caption = "Image"
            }
            if let bullets = element.bullets {
                output.bullets = bullets
                    .prefix(6)
                    .map { String($0.split(separator: " ").prefix(12).joined(separator: " ")) }
            }
            if let text = element.text {
                output.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return output
        }
    }
}
