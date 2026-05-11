import Foundation

extension GenSlidesScheme {
    func toSlideDeck() -> SlideDeck {
        let mappedSlides = slides.map { schemeSlide -> Slide in
            let elements = schemeSlide.elements.map { element -> SlideElement in
                switch element {
                case .text(let text):
                    var el = SlideElement(kind: .text)
                    el.text = text
                    el.width = 600
                    el.height = 60
                    return el

                case .bullets(let items):
                    var el = SlideElement(kind: .bullets)
                    el.bullets = items
                    el.width = 600
                    el.height = Double(items.count * 30 + 20)
                    return el

                case .image(let ref):
                    var el = SlideElement(kind: .image)
                    el.imageURL = URL(string: ref.url)
                    el.caption = ref.query
                    el.width = 400
                    el.height = 250
                    return el
                }
            }

            let bgHex = theme.gradient.first?.replacingOccurrences(of: "#", with: "") ?? "0F172A"

            return Slide(
                id: schemeSlide.id,
                type: schemeSlide.type.rawValue,
                title: schemeSlide.title,
                layout: mapLayout(schemeSlide.type),
                backgroundColorHex: bgHex,
                elements: elements,
                metadata: [
                    "alignment": schemeSlide.layout.alignment,
                    "spacing": String(schemeSlide.layout.spacing),
                    "accentColor": meta.accentColor,
                    "font": theme.font,
                    "glass": theme.glass ? "true" : "false",
                    "contrast": theme.contrast
                ]
            )
        }

        return SlideDeck(
            title: meta.title,
            theme: theme.gradient.first ?? "default",
            slides: mappedSlides,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func mapLayout(_ type: SchemeSlideType) -> String {
        switch type {
        case .title: return "centered"
        case .bullet: return "verticalList"
        case .image: return "imageCaption"
        case .twoColumn: return "splitHStack"
        case .chart: return "chart"
        case .gallery: return "gallery"
        }
    }
}
