import SwiftUI
import PhotosUI

public struct AIGenerateSlides: View {
    private let fallbackThemeGradient: [Color] = [.blue, .purple]
    @StateObject private var manager = AISlidesManager.shared
    @StateObject private var whiteboardStore = WhiteboardStore.shared
    @StateObject private var keyboardObserver = KeyboardObserver()

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
    @State private var showErrorAlert = false
    @State private var imagesExpanded = false
    @State private var keyboardThemeTab: Int = 0

    private var themesEnabled: Bool { WorkspaceSDKAI().isThemeScopeEnabled }

    public init() {}

    public var body: some View {
        ScrollView {
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

                // Themes & Styles are on the keyboard extension

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
        .keyboardGlow(keyboard: keyboardObserver)
        .navigationTitle("AI Slides")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if themesEnabled {
                    modernKeyboardExtension
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            DualKeyboardInputView(
                promptText: $rawText,
                tone: $tone,
                slideCount: $slideCount,
                selectedStyleID: $selectedStyleID,
                onSubmit: generate,
                keyboard: keyboardObserver
            )
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

    private var modernKeyboardExtension: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                keyboardTabButton(title: "Themes", icon: "paintpalette.fill", index: 0)
                keyboardTabButton(title: "Styles", icon: "slider.horizontal.3", index: 1)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            Divider().opacity(0.3).padding(.vertical, 2)

            Group {
                if keyboardThemeTab == 0 {
                    keyboardThemeStrip
                } else {
                    keyboardStyleStrip
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(.easeInOut(duration: 0.2), value: keyboardThemeTab)
        }
    }

    private func keyboardTabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { keyboardThemeTab = index }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(keyboardThemeTab == index ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(keyboardThemeTab == index ? Color.indigo.opacity(0.7) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(keyboardThemeTab == index ? Color.indigo : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var keyboardThemeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AIGenSlideCatalog.themes) { theme in
                    let isActive = selectedThemeID == theme.id
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedThemeID = theme.id
                        }
                    } label: {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: gradientColors(for: theme), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 20, height: 20)
                            Text(theme.name)
                                .font(.system(size: 11, weight: isActive ? .bold : .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isActive ? .ultraThinMaterial : .regularMaterial)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isActive ? LinearGradient(colors: gradientColors(for: theme), startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: isActive ? 2 : 0
                                )
                        )
                        .shadow(color: isActive ? .purple.opacity(0.4) : .clear, radius: 6, x: 0, y: 2)
                        .scaleEffect(isActive ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var keyboardStyleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AIGenSlideCatalog.styles) { style in
                    let isActive = selectedStyleID == style.id
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedStyleID = style.id
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isActive ? Color.cyan : Color.gray.opacity(0.4))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .opacity(isActive ? 1 : 0)
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(style.name)
                                    .font(.system(size: 11, weight: isActive ? .bold : .medium))
                                    .lineLimit(1)
                                Text(style.visualDensity.rawValue.capitalized)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isActive ? .ultraThinMaterial : .regularMaterial)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isActive ? Color.cyan : Color.clear, lineWidth: isActive ? 2 : 0)
                        )
                        .shadow(color: isActive ? .cyan.opacity(0.4) : .clear, radius: 6, x: 0, y: 2)
                        .scaleEffect(isActive ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
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
