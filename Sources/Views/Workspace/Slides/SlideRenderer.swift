import SwiftUI
import Charts

struct SlideRenderer: View {
    let slide: SchemeSlide
    let theme: SlideThemeSpec

    var body: some View {
        layoutContainer
            .padding(theme.glass ? 20 : 16)
            .background(slideBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var layoutContainer: some View {
        switch slide.type {
        case .title:
            titleLayout
        case .bullet:
            bulletLayout
        case .image:
            imageLayout
        case .twoColumn:
            twoColumnLayout
        case .chart:
            chartLayout
        case .gallery:
            galleryLayout
        }
    }

    // MARK: - Title Layout

    private var titleLayout: some View {
        VStack(spacing: CGFloat(slide.layout.spacing)) {
            Text(slide.title)
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            ForEach(Array(slide.elements.enumerated()), id: \.offset) { _, element in
                renderElement(element, fontSize: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bullet Layout

    private var bulletLayout: some View {
        VStack(alignment: .leading, spacing: CGFloat(slide.layout.spacing)) {
            Text(slide.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            ForEach(Array(slide.elements.enumerated()), id: \.offset) { _, element in
                renderElement(element, fontSize: 18)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Image Layout

    private var imageLayout: some View {
        VStack(spacing: CGFloat(slide.layout.spacing)) {
            Text(slide.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            ForEach(Array(slide.elements.enumerated()), id: \.offset) { _, element in
                renderElement(element, fontSize: 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Two Column Layout

    private var twoColumnLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(slide.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: CGFloat(slide.layout.spacing)) {
                let half = slide.elements.count / 2
                let leftElements = Array(slide.elements.prefix(max(1, half)))
                let rightElements = Array(slide.elements.suffix(from: max(1, half)))

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(leftElements.enumerated()), id: \.offset) { _, element in
                        renderElement(element, fontSize: 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(rightElements.enumerated()), id: \.offset) { _, element in
                        renderElement(element, fontSize: 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Chart Layout

    private var chartLayout: some View {
        VStack(spacing: CGFloat(slide.layout.spacing)) {
            Text(slide.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            ForEach(Array(slide.elements.enumerated()), id: \.offset) { _, element in
                renderElement(element, fontSize: 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Gallery Layout

    private var galleryLayout: some View {
        VStack(spacing: 12) {
            Text(slide.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            let imageElements = slide.elements.compactMap { element -> SchemeImageRef? in
                if case .image(let ref) = element { return ref }
                return nil
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(Array(imageElements.enumerated()), id: \.offset) { _, ref in
                    imageView(for: ref)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Element Rendering

    @ViewBuilder
    private func renderElement(_ element: SchemeSlideElement, fontSize: CGFloat) -> some View {
        switch element {
        case .text(let text):
            Text(text)
                .font(.system(size: fontSize))
                .foregroundStyle(.white.opacity(0.9))

        case .bullets(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(bullet)
                            .font(.system(size: fontSize))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }

        case .image(let ref):
            imageView(for: ref)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Image View

    @ViewBuilder
    private func imageView(for ref: SchemeImageRef) -> some View {
        if let url = URL(string: ref.url), !ref.url.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    imagePlaceholder(query: ref.query)
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    imagePlaceholder(query: ref.query)
                }
            }
        } else {
            imagePlaceholder(query: ref.query)
        }
    }

    private func imagePlaceholder(query: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(query)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Background

    private var slideBackground: some View {
        let colors = theme.gradient.compactMap { Color(hex: $0) }
        let gradientColors = colors.isEmpty ? [Color(red: 0.06, green: 0.09, blue: 0.17)] : colors

        return ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if theme.glass {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        }
    }

    private var accentColor: Color {
        Color(hex: theme.gradient.last ?? "#3B82F6") ?? .blue
    }
}

// MARK: - Scheme-based Slide Canvas

struct SchemeSlideCanvasView: View {
    let scheme: GenSlidesScheme
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 16) {
            if scheme.slides.indices.contains(currentIndex) {
                SlideRenderer(slide: scheme.slides[currentIndex], theme: scheme.theme)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }

            HStack {
                Button("Previous") { currentIndex = max(0, currentIndex - 1) }
                    .disabled(currentIndex == 0)
                Spacer()
                Text("\(currentIndex + 1)/\(max(scheme.slides.count, 1))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Next") { currentIndex = min(scheme.slides.count - 1, currentIndex + 1) }
                    .disabled(currentIndex >= scheme.slides.count - 1)
            }
        }
        .padding()
        .navigationTitle(scheme.meta.title)
    }
}
