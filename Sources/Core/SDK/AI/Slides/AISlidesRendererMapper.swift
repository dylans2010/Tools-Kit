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
        var output = source.map { item -> SlideElement in
            let kind = SlideElement.ElementKind(rawValue: item.kind.lowercased()) ?? .text
            var model = SlideElement(kind: kind)
            model.text = scaledText(item.text ?? "")
            model.bullets = (item.bullets ?? []).map(scaledText)
            model.caption = item.caption ?? ""
            model.width = max(160, min(760, model.width))
            model.height = max(40, min(300, model.height))

            if let textURL = item.text, kind == .image, !textURL.hasPrefix("data://"), let url = URL(string: textURL), url.scheme != nil {
                model.imageURL = url
                model.caption = item.caption ?? "Image"
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

        if let visuals, visuals.requiresVisual, output.allSatisfy({ $0.kind != .image && $0.kind != .chart }) {
            if visuals.chartSpec != nil {
                var chart = SlideElement(kind: .chart)
                chart.chartData = .init(title: "Pending Data", labels: ["Metric 1", "Metric 2", "Metric 3"], values: [1, 1, 1])
                output.append(chart)
            } else if let query = visuals.imageQuery {
                var image = SlideElement(kind: .image)
                image.caption = query
                output.append(image)
            }
        }

        if output.isEmpty {
            var fallback = SlideElement(kind: .text)
            fallback.text = "Content unavailable"
            output = [fallback]
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
