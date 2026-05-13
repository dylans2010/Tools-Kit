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

    func validate(content: SlideContentPayload, input: SlideInput) throws -> SlideContentPayload {
        var violations: [String] = []

        if content.slides.isEmpty {
            violations.append("No slides present in provider response")
        }

        for (offset, slide) in content.slides.enumerated() {
            if slide.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                violations.append("Slide \(offset) has an empty title")
            }
            if slide.elements.isEmpty {
                violations.append("Slide \(offset) has no elements")
            }
            for (elemIdx, elem) in slide.elements.enumerated() {
                if elem.kind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    violations.append("Slide \(offset), element \(elemIdx) has empty kind")
                }
            }
        }

        if !violations.isEmpty {
            throw AISlidesPipelineError.schemaValidationFailed(violations: violations)
        }

        var sanitized = content
        sanitized.slides = content.slides
            .prefix(max(input.slideCount, content.slides.count))
            .enumerated()
            .map { offset, slide in
                var fixed = slide
                fixed.index = offset
                fixed.title = String(slide.title.prefix(80))

                let validLayouts = validLayoutsByType[slide.type.lowercased()] ?? Set(["verticalList", "titleAndBody", "centered", "splitHStack"])
                if !validLayouts.contains(slide.layout) {
                    fixed.layout = validLayouts.first ?? "verticalList"
                }

                return fixed
            }

        return sanitized
    }
}
