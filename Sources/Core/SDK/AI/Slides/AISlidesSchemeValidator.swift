import Foundation

struct AISlidesSchemeValidator {
    func validate(_ scheme: GenSlidesScheme) throws -> GenSlidesScheme {
        print("[SchemeValidator] Validating \(scheme.slides.count) slides")

        if scheme.slides.count < 5 {
            throw SlideValidationError.insufficientSlides(count: scheme.slides.count)
        }

        var repaired = scheme

        for (slideIdx, slide) in repaired.slides.enumerated() {
            if slide.elements.isEmpty {
                throw SlideValidationError.emptySlide(index: slideIdx)
            }

            let wordCount = slide.title.split(separator: " ").count
            if wordCount > 8 {
                repaired.slides[slideIdx].title = slide.title.split(separator: " ").prefix(8).joined(separator: " ")
                print("[SchemeValidator] Trimmed title at slide \(slideIdx) from \(wordCount) to 8 words")
            }

            for (elemIdx, element) in slide.elements.enumerated() {
                switch element {
                case .text(let text):
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        throw SlideValidationError.emptyElement(slideIndex: slideIdx)
                    }

                case .bullets(let bullets):
                    if bullets.count > 6 {
                        repaired.slides[slideIdx].elements[elemIdx] = .bullets(Array(bullets.prefix(6)))
                        print("[SchemeValidator] Trimmed bullets at slide \(slideIdx) from \(bullets.count) to 6")
                    }
                    for (bIdx, bullet) in bullets.prefix(6).enumerated() {
                        let bulletWords = bullet.split(separator: " ").count
                        if bulletWords > 12 {
                            let trimmed = bullet.split(separator: " ").prefix(12).joined(separator: " ")
                            if case .bullets(var repairedBullets) = repaired.slides[slideIdx].elements[elemIdx] {
                                repairedBullets[bIdx] = trimmed
                                repaired.slides[slideIdx].elements[elemIdx] = .bullets(repairedBullets)
                            }
                            print("[SchemeValidator] Trimmed bullet \(bIdx) at slide \(slideIdx) from \(bulletWords) to 12 words")
                        }
                    }

                case .image(let ref):
                    if ref.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        throw SlideValidationError.emptyElement(slideIndex: slideIdx)
                    }
                }
            }
        }

        let titles = repaired.slides.map(\.title)
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
            print("[SchemeValidator] Warning: duplicate slide titles at indices \(duplicateIndices)")
        }

        print("[SchemeValidator] Validation passed: \(repaired.slides.count) slides")
        return repaired
    }
}
