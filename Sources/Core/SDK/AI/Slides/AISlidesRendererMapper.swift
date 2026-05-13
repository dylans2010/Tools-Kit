import Foundation

struct AISlidesRendererMapper {
    func mapLayout(for type: String) -> String {
        switch type.lowercased() {
        case "title": return "centered"
        case "bullet": return "verticalList"
        case "image": return "imageCaption"
        case "twocolumn", "two_column": return "splitHStack"
        case "chart": return "chart"
        default: return "verticalList"
        }
    }

    func mapElements(_ source: [SlideContentPayload.ContentSlide.ContentElement], visuals: VisualPlan.VisualSlide?) -> [SlideElement] {
        let output = source.map { item -> SlideElement in
            let kind = SlideElement.ElementKind(rawValue: item.kind.lowercased()) ?? .text
            var model = SlideElement(kind: kind)
            model.text = scaledText(item.text ?? "")
            model.bullets = (item.bullets ?? []).map(scaledText)
            model.caption = item.caption ?? ""
            model.width = max(160, min(760, model.width))
            model.height = max(40, min(300, model.height))

            if let textURL = item.text, kind == .image, !textURL.hasPrefix("upload://"), let url = URL(string: textURL), url.scheme != nil {
                model.imageURL = url
                model.caption = item.caption ?? ""
            }

            if let title = item.chartTitle,
               let labels = item.chartLabels,
               let values = item.chartValues,
               !labels.isEmpty,
               !values.isEmpty {
                model.chartData = .init(title: title, labels: labels, values: values)
                model.kind = .chart
            }

            return model
        }

        return output
    }

    private func scaledText(_ text: String) -> String {
        let words = text.split(separator: " ")
        if words.count > 32 {
            return words.prefix(32).joined(separator: " ") + "…"
        }
        return text
    }
}
