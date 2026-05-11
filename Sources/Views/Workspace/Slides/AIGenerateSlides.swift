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
    @State private var audience: SlideAudience = .internalTeam
    @State private var density: SlideVisualDensity = .medium
    @State private var includeImages = true
    @State private var selectedThemeID = AIGenSlideCatalog.defaultThemeID
    @State private var selectedStyleID = AIGenSlideCatalog.defaultStyleID
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var uploadedImages: [SlidePhotoAsset] = []

    @State private var generatedDeck: SlideDeck?

    @State private var inputExpanded = true
    @State private var themesExpanded = false
    @State private var stylesExpanded = false
    @State private var showErrorAlert = false
    @State private var imagesExpanded = false

    private var themesEnabled: Bool { WorkspaceSDKAI().isThemeScopeEnabled }

    public init() {}

    public var body: some View {
        let topColor: Color = .indigo.opacity(0.25)
        let bottomColor: Color = .cyan.opacity(0.15)
        let backgroundColors: [Color] = [topColor, .purple.opacity(0.12), bottomColor]
        let backgroundGradient = LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Input Sources
                glassCard {
                    DisclosureGroup("Input Sources", isExpanded: $inputExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
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


                            Divider().padding(.vertical, 4)
                            Text("Advanced Settings")
                                .font(.subheadline.weight(.semibold))
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
                        }
                        .padding(.top, 8)
                    }
                    .font(.headline)
                }

                // Theme Selection
                if themesEnabled {
                    glassCard {
                        DisclosureGroup("Themes", isExpanded: $themesExpanded) {
                            themeGrid
                                .padding(.top, 8)
                        }
                        .font(.headline)
                    }

                    glassCard {
                        DisclosureGroup("Styles", isExpanded: $stylesExpanded) {
                            styleGrid
                                .padding(.top, 8)
                        }
                        .font(.headline)
                    }
                }

                // Image Upload
                glassCard {
                    DisclosureGroup("Image Upload", isExpanded: $imagesExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
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

                            Toggle("Include AI Images", isOn: $includeImages)
                        }
                        .padding(.top, 8)
                    }
                    .font(.headline)
                }

                // Generate Button with neon glow
                Button(action: generate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(manager.isGenerating ? "Generating..." : "Generate Slides")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(manager.isGenerating)
                .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)

                if manager.isGenerating {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: manager.progressValue)
                            .tint(.cyan)
                        Text(manager.progressMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let scheme = manager.latestScheme {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Slide Preview (GenSlidesScheme)")
                            .font(.headline)
                        Text(scheme.meta.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        NavigationLink("View Full Presentation") {
                            SchemeSlideCanvasView(scheme: scheme)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                            ForEach(scheme.slides) { slide in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(slide.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(slide.type.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(slide.elements.count) elements")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(colors: [.cyan.opacity(0.4), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .shadow(color: .cyan.opacity(0.15), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                } else if let deck = generatedDeck ?? manager.latestDeck {
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
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        LinearGradient(colors: [.purple.opacity(0.4), .cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                    .shadow(color: .purple.opacity(0.15), radius: 4, x: 0, y: 2)
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
            backgroundGradient
                .ignoresSafeArea()
        )
        .navigationTitle("AI Slides")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if themesEnabled {
                    Text("Theme")
                        .font(.caption)
                    themeAccessoryRow
                    Divider()
                    Text("Style")
                        .font(.caption)
                    styleAccessoryRow
                }
            }
        }
        .alert("Generation Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(manager.lastError ?? "Something went wrong.")
        }
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
                    .shadow(color: selectedThemeID == theme.id ? .purple.opacity(0.4) : .clear, radius: 6, x: 0, y: 2)
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
                            .stroke(selectedStyleID == style.id ? Color.cyan : Color.gray.opacity(0.35), lineWidth: selectedStyleID == style.id ? 2 : 1)
                    )
                    .shadow(color: selectedStyleID == style.id ? .cyan.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var themeAccessoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AIGenSlideCatalog.themes) { theme in
                    Circle()
                        .fill(LinearGradient(colors: gradientColors(for: theme), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(selectedThemeID == theme.id ? Color.white : .clear, lineWidth: 2))
                        .shadow(color: .purple.opacity(selectedThemeID == theme.id ? 0.7 : 0.25), radius: 6)
                        .onTapGesture { selectedThemeID = theme.id }
                }
            }
        }
    }

    private var styleAccessoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AIGenSlideCatalog.styles) { style in
                    Circle()
                        .fill(selectedStyleID == style.id ? Color.cyan : Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.cyan.opacity(0.6), lineWidth: 1))
                        .shadow(color: .cyan.opacity(selectedStyleID == style.id ? 0.7 : 0.25), radius: 6)
                        .onTapGesture { selectedStyleID = style.id }
                }
            }
        }
    }

    @ViewBuilder
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) { content() }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func gradientColors(for theme: SlideTheme) -> [Color] {
        let mapped = theme.gradient.compactMap(colorFromHex)
        return mapped.ifEmpty(fallbackThemeGradient)
    }

    private func colorFromHex(_ hex: String) -> Color? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let intValue = Int(value, radix: 16) else { return nil }

        let red = Double((intValue >> 16) & 0xFF) / 255.0
        let green = Double((intValue >> 8) & 0xFF) / 255.0
        let blue = Double(intValue & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
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
            do {
                generatedDeck = try await manager.generate(input: input)
            } catch {
                generatedDeck = nil
                await MainActor.run {
                    showErrorAlert = true
                }
            }
        }
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}
