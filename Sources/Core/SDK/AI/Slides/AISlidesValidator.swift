import Foundation

struct AISlidesValidator {
    func validate(_ payload: SlideContentPayload) -> SlideContentPayload {
        var sanitized = payload
        sanitized.slides = payload.slides.map { slide in
            var fixed = slide
            fixed.title = String(slide.title.split(separator: " ").prefix(8).joined(separator: " "))
            fixed.elements = slide.elements.map { element in
                var output = element
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
            return fixed
        }
        return sanitized
    }
}
