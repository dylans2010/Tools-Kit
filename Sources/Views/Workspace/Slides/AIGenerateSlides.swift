import SwiftUI
import PhotosUI

public struct AIGenerateSlides: View {
    private let fallbackThemeGradient: [Color] = [.blue, .purple]
    @StateObject private var manager = AISlidesManager.shared
    @StateObject private var whiteboardStore = WhiteboardStore.shared

    @State private var rawText = ""
    @State private var notes = ""
    @State private var documents = ""
    @State private var selectedBoardID: UUID?
    @State private var slideCount = 8
    @State private var tone: SlideTone = .formal
    @State private var audience: SlideAudience = .internal
    @State private var density: SlideVisualDensity = .medium
    @State private var includeImages = true
    @State private var selectedThemeID = AIGenSlideCatalog.defaultThemeID
    @State private var selectedStyleID = AIGenSlideCatalog.defaultStyleID
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var uploadedImages: [SlidePhotoAsset] = []

    @State private var generatedDeck: SlideDeck?

    private var themesEnabled: Bool { WorkspaceSDKAI().isThemeScopeEnabled }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Input")
                            .font(.headline)
                        TextField("Topic or presentation goal", text: $rawText, axis: .vertical)
                            .lineLimit(2...5)
                        TextField("Notes (one per line)", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                        TextField("Document snippets", text: $documents, axis: .vertical)
                            .lineLimit(2...5)

                        Picker("Whiteboard", selection: $selectedBoardID) {
                            Text("None").tag(UUID?.none)
                            ForEach(whiteboardStore.boards) { board in
                                Text(board.title).tag(UUID?.some(board.id))
                            }
                        }

                        PhotosPicker(selection: $selectedImages, matching: .images) {
                            Label("Import Photos", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                        }
                        .onChange(of: selectedImages) { _, newItems in
                            Task {
                                var assets: [SlidePhotoAsset] = []
                                for (index, item) in newItems.enumerated() {
                                    if let data = try? await item.loadTransferable(type: Data.self) {
                                        assets.append(SlidePhotoAsset(fileName: "photo_\(index + 1).jpg", dataBase64: data.base64EncodedString()))
                                    }
                                }
                                uploadedImages = assets
                            }
                        }

                        if !uploadedImages.isEmpty {
                            Text("\(uploadedImages.count) image(s) ready")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configuration")
                            .font(.headline)

                        HStack {
                            Text("Slide Count")
                            Spacer()
                            Text("\(slideCount)")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(get: { Double(slideCount) }, set: { slideCount = Int($0) }), in: 5...15, step: 1)

                        Picker("Tone", selection: $tone) {
                            ForEach(SlideTone.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Audience", selection: $audience) {
                            ForEach(SlideAudience.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Visual Density", selection: $density) {
                            ForEach(SlideVisualDensity.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Toggle("Include Images", isOn: $includeImages)
                    }
                }

                if themesEnabled {
                    card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Themes")
                                .font(.headline)
                            themeGrid
                            Text("Styles")
                                .font(.headline)
                            styleGrid
                        }
                    }
                }

                Button(action: generate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(manager.isGenerating ? "Generating..." : "Generate Slides")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isGenerating)

                if manager.isGenerating {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: manager.progressValue)
                        Text(manager.progressMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let deck = generatedDeck ?? manager.latestDeck {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Slide Preview")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                            ForEach(deck.slides) { slide in
                                NavigationLink {
                                    SlideCanvasView(deck: deck, startAt: slide.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(slide.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                        Text(slide.type.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [.indigo.opacity(0.20), .cyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle("AI Slides")
    }

    private var themeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            ForEach(AIGenSlideCatalog.themes) { theme in
                Button {
                    selectedThemeID = theme.id
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(theme.name)
                            .font(.subheadline.weight(.semibold))
                        Text(theme.font)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: gradientColors(for: theme), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .opacity(0.82)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedThemeID == theme.id ? Color.white : Color.white.opacity(0.22), lineWidth: selectedThemeID == theme.id ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var styleGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            ForEach(AIGenSlideCatalog.styles) { style in
                Button {
                    selectedStyleID = style.id
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(style.name)
                            .font(.subheadline.weight(.semibold))
                        Text(style.visualDensity.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedStyleID == style.id ? Color.blue : Color.gray.opacity(0.35), lineWidth: selectedStyleID == style.id ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) { content() }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func gradientColors(for theme: SlideTheme) -> [Color] {
        let mapped = theme.gradient.compactMap { Color(hex: $0) }
        return mapped.ifEmpty(fallbackThemeGradient)
    }

    private func generate() {
        let board = whiteboardStore.boards.first(where: { $0.id == selectedBoardID })
        let input: SlideInput

        if let board {
            input = WhiteboardAIEngine().slideInput(
                from: board,
                rawText: rawText,
                tone: tone,
                audience: audience,
                slideCount: slideCount,
                includeImages: includeImages,
                density: density,
                uploadedImages: uploadedImages,
                preferredThemeID: themesEnabled ? selectedThemeID : nil,
                preferredStyleID: themesEnabled ? selectedStyleID : nil
            )
        } else {
            input = SlideInput(
                rawText: rawText,
                notes: notes.split(separator: "\n").map(String.init),
                whiteboardNodes: [],
                documents: documents.split(separator: "\n").map(String.init),
                uploadedImages: uploadedImages,
                tone: tone,
                audience: audience,
                slideCount: slideCount,
                includeImages: includeImages,
                visualDensity: density,
                preferredThemeID: themesEnabled ? selectedThemeID : nil,
                preferredStyleID: themesEnabled ? selectedStyleID : nil
            )
        }

        Task {
            generatedDeck = await manager.generate(input: input)
        }
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}
