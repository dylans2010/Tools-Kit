import Foundation

struct AISlidesSchemaEnforcer: Sendable {
    private let validLayoutsByType: [String: Set<String>] = [
        "title": ["centered", "title"],
        "bullet": ["verticalList", "titleAndBody"],
        "image": ["imageCaption", "splitHStack"],
        "chart": ["chart", "splitHStack"],
        "twocolumn": ["splitHStack"],
        "two_column": ["splitHStack"]
    ]

    func enforce(content: SlideContentPayload, input: SlideInput) throws -> SlideContentPayload {
        var violations: [String] = []
        var enforced = content

        if enforced.slides.isEmpty {
            violations.append("Provider returned zero slides")
        }

        if enforced.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            violations.append("Missing presentation title")
        }

        enforced.slides = enforced.slides.enumerated().map { offset, slide in
            var fixed = slide
            fixed.index = offset

            if slide.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                violations.append("Slide \(offset) has empty title")
            }
            fixed.title = String(slide.title.prefix(80))

            if slide.elements.isEmpty {
                violations.append("Slide \(offset) has no elements")
            }

            fixed.elements = slide.elements.compactMap { element in
                let kind = element.kind.lowercased()
                if kind == "text", let text = element.text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    violations.append("Slide \(offset) has empty text element")
                    return nil
                }
                if kind == "bullets", let bullets = element.bullets, bullets.isEmpty {
                    violations.append("Slide \(offset) has empty bullets element")
                    return nil
                }
                return element
            }

            let validLayouts = validLayoutsByType[slide.type.lowercased()] ?? Set(["verticalList", "titleAndBody", "centered", "splitHStack"])
            if !validLayouts.contains(slide.layout) {
                fixed.layout = validLayouts.first ?? "verticalList"
            }

            return fixed
        }

        if !violations.isEmpty {
            let hasContentViolations = violations.contains(where: {
                $0.contains("zero slides") || $0.contains("has no elements")
            })
            if hasContentViolations {
                throw AISlidesPipelineError.schemaValidationFailed(violations: violations)
            }
        }

        return enforced
    }
}
