import SwiftUI
import PhotosUI
import Aurora

public struct AIGenerateSlides: View {
    private let fallbackThemeGradient: [Color] = [.blue, .purple]
    @StateObject private var manager = AISlidesManager.shared
    @StateObject private var whiteboardStore = WhiteboardStore.shared
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showingKeyboardSheet = false
    @State private var selectedSuggestion: SlideSuggestion?

    // All text input state is owned here but edited exclusively via the keyboard extension.
    @State private var rawText = ""
    @State private var notes = ""
    @State private var documents = ""
    @State private var activeField: SlideInputField = .prompt

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

    @FocusState private var isFieldFocused: Bool

    private var themesEnabled: Bool { WorkspaceSDKAI().isThemeScopeEnabled }

    public init() {}

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let scheme = manager.latestScheme {
                        schemePreview(scheme)
                    } else if let deck = generatedDeck ?? manager.latestDeck {
                        deckPreview(deck)
                    } else if !manager.isGenerating {
                        emptyState
                    }
                }
                .padding()
            }
            .opacity(manager.isGenerating ? 0.2 : 1)
            .blur(radius: manager.isGenerating ? 5 : 0)

            if manager.isGenerating {
                loadingOverlay
            }
        }
        .animation(.smooth, value: manager.isGenerating)
        .keyboardGlow(keyboard: keyboardObserver)
        .aiAnimationLoading(manager.isGenerating) // Extension handles timing
        .navigationTitle("AI Slides")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            compactInputTray
        }
        .alert("Generation Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(manager.lastError ?? "Something went wrong.")
        }
        .onAppear { isFieldFocused = true }
        .sheet(item: Binding(get: { generatedDeck }, set: { generatedDeck = $0 })) { deck in
            AIGenSlidesPreview(deck: deck)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 4) {
                Text("Design Smarter")
                    .font(.headline)
                Text("Transform your ideas into professional slide decks with AI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 32) {
            ProgressView()
                .controlSize(.large)
                .tint(.blue)

            VStack(spacing: 12) {
                Text(manager.progressMessage)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("\(Int(manager.progressValue * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
    }

    private var compactInputTray: some View {
        VStack(spacing: 8) {
            if !manager.isGenerating && rawText.isEmpty {
                suggestionsStrip
                    .padding(.horizontal, -16) // Bleed to edges
            }

            DualKeyboardInputView(
                    promptText: $rawText,
                    notesText: $notes,
                    documentsText: $documents,
                    activeField: $activeField,
                    tone: $tone,
                    slideCount: $slideCount,
                    selectedStyleID: $selectedStyleID,
                    selectedThemeID: $selectedThemeID,
                    onSubmit: generate,
                    keyboard: keyboardObserver,
                    isFocused: $isFieldFocused
                )
                .padding(.bottom, 4)
            }
        }
        .alert("Generation Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(manager.lastError ?? "Something went wrong.")
        }
        .onAppear {
            isFieldFocused = true
        }
        .sheet(isPresented: $showingKeyboardSheet) {
            ZStack {
                AuroraGlow(.dramatic)
                    .palette(.appleIntelligence)
                    .direction(.bottomToTop)
                    .washSweepDuration(1.2)
                    .washPulseWidth(1.0)
                    .washPeak(0.6)
                    .opacity(keyboardObserver.isVisible ? 1 : 0)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .presentationDetents([.height(max(300, keyboardObserver.height + 80))])
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onChange(of: keyboardObserver.isVisible) { _, visible in
            showingKeyboardSheet = visible
            if !visible {
                // Re-focus to keep keyboard open
                isFieldFocused = true
            }
        }
        .sheet(item: Binding(get: { generatedDeck }, set: { generatedDeck = $0 })) { deck in
            AIGenSlidesPreview(deck: deck)
        }
    }

    // MARK: - Field Selector

    private var fieldSelectorRow: some View {
        HStack(spacing: 8) {
            ForEach(SlideInputField.allCases, id: \.self) { field in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        activeField = field
                    }
                    isFieldFocused = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: field.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(field.label)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(activeField == field
                                  ? Color(.systemIndigo).opacity(0.22)
                                  : Color(.systemGray5).opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                activeField == field
                                    ? Color(.systemIndigo).opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(activeField == field ? Color(.systemIndigo) : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeFieldPreview: some View {
        Group {
            switch activeField {
            case .prompt:
                fieldBubble(text: rawText, placeholder: "Topic or presentation goal")
            case .notes:
                fieldBubble(text: notes, placeholder: "Notes (one per line)")
            case .documents:
                fieldBubble(text: documents, placeholder: "Document snippets")
            }
        }
    }

    private func fieldBubble(text: String, placeholder: String) -> some View {
        Text(text.isEmpty ? placeholder : text)
            .font(.subheadline)
            .foregroundStyle(text.isEmpty ? .tertiary : .primary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.5))
            )
            .contentShape(Rectangle())
    }

    // MARK: - Previews

    @ViewBuilder
    private func schemePreview(_ scheme: GenSlidesScheme) -> some View {
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
                    .background(slideCardBackground)
                    .shadow(color: .cyan.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
        }
    }

    @ViewBuilder
    private func deckPreview(_ deck: SlideDeck) -> some View {
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
                        .background(slideCardBackground)
                        .shadow(color: .purple.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var slideCardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.4), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Glass Card

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
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helpers

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
                        LinearGradient(
                            colors: gradientColors(for: theme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.82)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedThemeID == theme.id ? Color.white : Color.white.opacity(0.22),
                                lineWidth: selectedThemeID == theme.id ? 2 : 1
                            )
                    )
                    .shadow(
                        color: selectedThemeID == theme.id ? .purple.opacity(0.4) : .clear,
                        radius: 6, x: 0, y: 2
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
                            .stroke(
                                selectedStyleID == style.id ? Color.cyan : Color.gray.opacity(0.35),
                                lineWidth: selectedStyleID == style.id ? 2 : 1
                            )
                    )
                    .shadow(
                        color: selectedStyleID == style.id ? .cyan.opacity(0.3) : .clear,
                        radius: 4, x: 0, y: 2
                    )
                }
                .buttonStyle(.plain)
            }
        }
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

    private var suggestionsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slideSuggestions.prefix(6)) { suggestion in
                    Button {
                        rawText = suggestion.prompt
                        generate()
                    } label: {
                        Text(suggestion.title)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                            .overlay(Capsule().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Input Field Enum

enum SlideInputField: String, CaseIterable {
    case prompt
    case notes
    case documents

    var label: String {
        switch self {
        case .prompt: return "Prompt"
        case .notes: return "Notes"
        case .documents: return "Docs"
        }
    }

    var icon: String {
        switch self {
        case .prompt: return "text.bubble"
        case .notes: return "note.text"
        case .documents: return "doc.text"
        }
    }

    var placeholder: String {
        switch self {
        case .prompt: return "Topic or presentation goal..."
        case .notes: return "Notes (one per line)..."
        case .documents: return "Document snippets..."
        }
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}

private struct SlideSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let themeID: String
    let styleID: String
    let prompt: String
    let notes: [String]
}

private let slideSuggestions: [SlideSuggestion] = (1...25).map { i in
    SlideSuggestion(
        title: "Suggestion \(i)",
        themeID: AIGenSlideCatalog.defaultThemeID,
        styleID: AIGenSlideCatalog.defaultStyleID,
        prompt: """
        {"theme":"\(AIGenSlideCatalog.defaultThemeID)","style":"\(AIGenSlideCatalog.defaultStyleID)","prompt":"Create a polished presentation concept #\(i) with an executive storyline, visuals, and actionable insights."}
        """,
        notes: ["Audience: leadership", "Goal: decision-ready", "Include data storytelling"]
    )
}
