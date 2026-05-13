import SwiftUI
import Charts

struct SlideCanvasView: View {
    let deck: SlideDeck
    let startAt: UUID?

    @State private var index = 0

    init(deck: SlideDeck, startAt: UUID? = nil) {
        self.deck = deck
        self.startAt = startAt
    }

    var body: some View {
        VStack(spacing: 16) {
            if deck.slides.indices.contains(index) {
                render(slide: deck.slides[index])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack {
                Button("Previous") { index = max(0, index - 1) }
                    .disabled(index == 0)
                Spacer()
                Text("\(index + 1)/\(max(deck.slides.count, 1))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Next") { index = min(deck.slides.count - 1, index + 1) }
                    .disabled(index >= deck.slides.count - 1)
            }
        }
        .padding()
        .navigationTitle(deck.title)
        .onAppear {
            if let startAt, let found = deck.slides.firstIndex(where: { $0.id == startAt }) {
                index = found
            }
        }
    }

    @ViewBuilder
    private func render(slide: Slide) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(slide.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            ForEach(slide.elements) { element in
                switch element.kind {
                case .text:
                    Text(element.text)
                        .foregroundStyle(.white)
                case .bullets:
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(element.bullets, id: \.self) { bullet in
                            Text("• \(bullet)")
                                .foregroundStyle(.white)
                        }
                    }
                case .image:
                    VStack(alignment: .leading, spacing: 6) {
                        Text(element.caption.isEmpty ? "Image" : element.caption)
                            .foregroundStyle(.white)
                            .font(.headline)
                        if let url = element.imageURL {
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                case .chart:
                    if let chartData = element.chartData {
                        Chart(Array(zip(chartData.labels, chartData.values)), id: \.0) { label, value in
                            BarMark(x: .value("Label", label), y: .value("Value", value))
                                .foregroundStyle(.cyan)
                        }
                        .frame(height: 220)
                    }
                case .shape:
                    RoundedRectangle(cornerRadius: CGFloat(element.cornerRadius))
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 180, height: 90)
                }
            }
            Spacer()
        }
    }
}
