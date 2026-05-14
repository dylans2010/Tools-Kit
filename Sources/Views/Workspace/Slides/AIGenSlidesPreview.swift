import SwiftUI
import Aurora

struct AIGenSlidesPreview: View {
    @StateObject private var manager = SlideDecksManager.shared
    let deck: SlideDeck
    @State private var currentSlideIndex = 0
    @Environment(\.dismiss) private var dismiss

    private var resolvedTheme: SlideTheme? {
        AIGenSlideCatalog.themes.first { $0.id == deck.theme || $0.name == deck.theme }
            ?? AIGenSlideCatalog.themes.first { $0.id == AIGenSlideCatalog.defaultThemeID }
    }


    var body: some View {
        NavigationStack {
            VStack {
                // Slide Content
                TabView(selection: $currentSlideIndex) {
                    ForEach(0..<deck.slides.count, id: \.self) { index in
                        SlidePreviewCard(slide: deck.slides[index], theme: resolvedTheme)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Controls
                HStack(spacing: 20) {
                    ActionButton(title: "Discard", icon: "trash", color: .red) {
                        dismiss()
                    }

                    ActionButton(title: "Try Again", icon: "arrow.clockwise", color: .orange) {
                        // Logic to regenerate would go here, for now just dismiss to main view
                        dismiss()
                    }

                    ActionButton(title: "Apply", icon: "checkmark", color: .green) {
                        // Logic to confirm and proceed
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("Preview: \(deck.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SlideEditorView(deck: deck, manager: manager)
                    } label: {
                        Text("Edit")
                    }
                }
            }
        }
    }
}

struct SlidePreviewCard: View {
    let slide: Slide
    let theme: SlideTheme?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(slide.title)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(slide.type.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.2), in: Capsule())
                .foregroundColor(.white)

            Spacer()

            // Actual slide content elements
            VStack(alignment: .leading, spacing: 8) {
                ForEach(slide.elements.prefix(5)) { element in
                    Group {
                        switch element.kind {
                        case .text:
                            Text(element.text)
                                .font(.system(size: CGFloat(element.fontSize / 1.5)))
                        case .bullets:
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(element.bullets, id: \.self) { bullet in
                                    Text("• \(bullet)")
                                }
                            }
                        case .image:
                            Label(element.caption.isEmpty ? "Image" : element.caption, systemImage: "photo")
                        case .chart:
                            Label(element.chartData?.title ?? "Chart", systemImage: "chart.bar.fill")
                        case .shape:
                            Label(element.shapeKind.displayName, systemImage: "square.dashed")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .padding(20)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.5), lineWidth: 1))
        }
    }
}
