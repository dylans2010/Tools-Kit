import Foundation

struct AISlidesSchemeValidator {
    func validate(_ scheme: GenSlidesScheme) throws -> GenSlidesScheme {
        if scheme.slides.count < 5 {
            throw SlideValidationError.insufficientSlides(count: scheme.slides.count)
        }

        for (slideIdx, slide) in scheme.slides.enumerated() {
            if slide.elements.isEmpty {
                throw SlideValidationError.emptySlide(index: slideIdx)
            }

            let wordCount = slide.title.split(separator: " ").count
            if wordCount > 8 {
                throw SlideValidationError.titleTooLong(slideIndex: slideIdx, title: slide.title)
            }

            for element in slide.elements {
                switch element {
                case .text(let text):
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        throw SlideValidationError.emptyElement(slideIndex: slideIdx)
                    }

                case .bullets(let bullets):
                    if bullets.count > 6 {
                        throw SlideValidationError.tooManyBullets(slideIndex: slideIdx, count: bullets.count)
                    }
                    for (bIdx, bullet) in bullets.enumerated() {
                        let bulletWords = bullet.split(separator: " ").count
                        if bulletWords > 12 {
                            throw SlideValidationError.bulletTooLong(slideIndex: slideIdx, bulletIndex: bIdx)
                        }
                    }

                case .image(let ref):
                    if ref.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        throw SlideValidationError.emptyElement(slideIndex: slideIdx)
                    }
                }
            }
        }

        let titles = scheme.slides.map(\.title)
        var seen = Set<String>()
        var duplicateIndices: [Int] = []
        for (idx, title) in titles.enumerated() {
            let normalized = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if seen.contains(normalized) {
                duplicateIndices.append(idx)
            }
            seen.insert(normalized)
        }
        if !duplicateIndices.isEmpty {
            throw SlideValidationError.duplicateSlide(indices: duplicateIndices)
        }

        return scheme
    }
}
