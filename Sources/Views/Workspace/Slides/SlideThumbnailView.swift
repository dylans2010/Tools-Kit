import SwiftUI

struct SlideThumbnailView: View {
    let slide: Slide
    var showTitle: Bool = false

    private var bgColor: Color {
        Color(hex: slide.backgroundColorHex) ?? Color(red: 0.12, green: 0.23, blue: 0.37)
    }

    var body: some View {
        ZStack {
            bgColor

            ForEach(slide.elements) { element in
                elementPreview(element)
                    .position(x: element.x, y: element.y)
            }

            if showTitle {
                VStack {
                    Spacer()
                    Text(slide.title)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 6)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func elementPreview(_ el: SlideElement) -> some View {
        switch el.kind {
        case .text, .bullets:
            Text(el.text)
                .font(.system(size: el.fontSize * 0.3))
                .foregroundColor(Color(hex: el.textColor) ?? .white)
                .frame(width: el.width * 0.3, height: el.height * 0.3)
        case .image:
            if let data = el.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: el.width * 0.3, height: el.height * 0.3)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: el.width * 0.3, height: el.height * 0.3)
            }
        case .chart:
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.18))
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .frame(width: el.width * 0.3, height: el.height * 0.3)
        case .shape:
            shapePreview(el)
        }
    }

    @ViewBuilder
    private func shapePreview(_ el: SlideElement) -> some View {
        let fill = Color(hex: el.fillColor) ?? .blue
        let w = el.width * 0.3
        let h = el.height * 0.3
        switch el.shapeKind {
        case .rectangle:
            RoundedRectangle(cornerRadius: el.cornerRadius * 0.3)
                .fill(fill)
                .frame(width: w, height: h)
        case .circle:
            Circle()
                .fill(fill)
                .frame(width: w, height: h)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .frame(width: w, height: h)
        }
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
