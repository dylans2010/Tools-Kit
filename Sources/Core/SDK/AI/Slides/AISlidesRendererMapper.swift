import Foundation

struct AISlidesRendererMapper {
    enum RendererType: String {
        case title
        case bullet
        case image
        case twoColumn
        case chart
    }

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
            model.text = item.text ?? ""
            model.bullets = item.bullets ?? []
            model.caption = item.caption ?? ""
            if let title = item.chartTitle,
               let labels = item.chartLabels,
               let values = item.chartValues {
                model.chartData = .init(title: title, labels: labels, values: values)
                model.kind = .chart
            }
            return model
        }

        if let visuals, visuals.requiresVisual, output.allSatisfy({ $0.kind != .image && $0.kind != .chart }) {
            if visuals.chartSpec != nil {
                var chart = SlideElement(kind: .chart)
                chart.chartData = .init(title: "Chart", labels: ["A", "B", "C"], values: [30, 45, 25])
                output.append(chart)
            } else if visuals.imageQuery != nil {
                var image = SlideElement(kind: .image)
                image.caption = visuals.imageQuery ?? ""
                output.append(image)
            }
        }

        return output
    }
}
