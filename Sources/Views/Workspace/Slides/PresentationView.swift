import SwiftUI

struct PresentationView: View {
    let deck: SlideDeck
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentIndex) {
                ForEach(Array(deck.slides.enumerated()), id: \.offset) { idx, slide in
                    FullSlideView(slide: slide)
                        .tag(idx)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .ignoresSafeArea()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
    }
}

private struct FullSlideView: View {
    let slide: Slide

    private var bgColor: Color {
        Color(hex: slide.backgroundColorHex)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                bgColor.ignoresSafeArea()

                ForEach(slide.elements) { element in
                    elementView(element, geo: geo)
                        .position(x: element.x * geo.size.width / 390,
                                  y: element.y * geo.size.height / 844)
                        .zIndex(Double(element.zIndex))
                }
            }
        }
    }

    @ViewBuilder
    private func elementView(_ el: SlideElement, geo: GeometryProxy) -> some View {
        let scaleX = geo.size.width / 390
        let scaleY = geo.size.height / 844
        let w = el.width * scaleX
        let h = el.height * scaleY

        switch el.kind {
        case .text, .bullets:
            Text(el.text)
                .font(.system(size: el.fontSize * scaleX))
                .foregroundColor(Color(hex: el.textColor))
                .multilineTextAlignment(textAlignmentFor(el.textAlignment))
                .frame(width: w, height: h)

        case .image:
            if let data = el.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: w, height: h)
            }

        case .chart:
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.16))
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.white)
                    Text(el.chartData?.title ?? "Chart")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: w, height: h)

        case .shape:
            shapeView(el, width: w, height: h)
        }
    }

    @ViewBuilder
    private func shapeView(_ el: SlideElement, width: CGFloat, height: CGFloat) -> some View {
        let fill = Color(hex: el.fillColor)
        switch el.shapeKind {
        case .rectangle:
            RoundedRectangle(cornerRadius: el.cornerRadius)
                .fill(fill)
                .frame(width: width, height: height)
        case .circle:
            Circle()
                .fill(fill)
                .frame(width: width, height: height)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .frame(width: width, height: height)
        }
    }

    private func textAlignmentFor(_ alignment: String) -> TextAlignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
}
