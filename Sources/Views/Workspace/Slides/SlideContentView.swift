import SwiftUI
import Charts

struct SlideContentView: View {
    let slide: Slide

    var body: some View {
        ZStack {
            (Color(hex: slide.backgroundColorHex))

            if let bgData = slide.backgroundImageData, let img = UIImage(data: bgData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.3)
            }

            ForEach(slide.elements) { element in
                ElementRenderer(element: element)
                    .position(x: element.x, y: element.y)
            }
        }
    }
}

struct ElementRenderer: View {
    let element: SlideElement

    var body: some View {
        Group {
            switch element.kind {
            case .text:
                Text(element.text)
                    .font(.system(size: element.fontSize, weight: fontWeight))
                    .foregroundColor(Color(hex: element.textColor))
                    .multilineTextAlignment(textAlignment)

            case .bullets:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(element.bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color(hex: element.textColor))
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(bullet)
                                .font(.system(size: element.fontSize * 0.8))
                                .foregroundColor(Color(hex: element.textColor))
                        }
                    }
                }

            case .image:
                if let data = element.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if let url = element.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            imagePlaceholder
                        case .empty:
                            ProgressView()
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }

            case .chart:
                if let chartData = element.chartData, !chartData.labels.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !chartData.title.isEmpty {
                            Text(chartData.title)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                        Chart(Array(zip(chartData.labels, chartData.values)), id: \.0) { label, value in
                            BarMark(x: .value("Label", label), y: .value("Value", value))
                                .foregroundStyle(.cyan)
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

            case .shape:
                shapeView
            }
        }
        .frame(width: element.width, height: element.height)
    }

    private var fontWeight: Font.Weight {
        switch element.fontWeight.lowercased() {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        default: return .regular
        }
    }

    private var textAlignment: TextAlignment {
        switch element.textAlignment.lowercased() {
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        default: return .center
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        let fill = Color(hex: element.fillColor)
        switch element.shapeKind {
        case .rectangle:
            RoundedRectangle(cornerRadius: element.cornerRadius)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: element.cornerRadius)
                        .stroke(Color(hex: element.strokeColor), lineWidth: element.strokeWidth)
                )
        case .circle:
            Circle()
                .fill(fill)
                .overlay(Circle().stroke(Color(hex: element.strokeColor), lineWidth: element.strokeWidth))
        case .triangle:
            TriangleShape()
                .fill(fill)
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .foregroundStyle(.white.opacity(0.5))
                if !element.caption.isEmpty {
                    Text(element.caption)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                }
            }
        }
    }
}
