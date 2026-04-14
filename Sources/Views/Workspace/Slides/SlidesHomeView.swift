import SwiftUI

struct SlidesHomeView: View {
    @StateObject private var manager = SlideDecksManager.shared
    @State private var showingCreate = false
    @State private var showingAIGenerate = false
    @State private var newDeckTitle = ""
    @State private var aiPrompt = ""
    @State private var isGenerating = false
    @State private var generationError: String? = nil
    @State private var deckToDelete: SlideDeck? = nil
    @State private var showDeleteConfirm = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerActions

                if manager.decks.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.on.rectangle.angled",
                        title: "No Presentations",
                        message: "Create your first slide deck or let AI build one for you.",
                        action: { showingCreate = true },
                        actionLabel: "Create Deck"
                    )
                } else {
                    Text("Your Decks")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(manager.decks) { deck in
                            NavigationLink {
                                SlideEditorView(deck: deck, manager: manager)
                            } label: {
                                DeckCard(deck: deck) {
                                    deckToDelete = deck
                                    showDeleteConfirm = true
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Slides")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            createDeckSheet
        }
        .sheet(isPresented: $showingAIGenerate) {
            aiGenerateSheet
        }
        .confirmationDialog("Delete \"\(deckToDelete?.title ?? "")\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let d = deckToDelete { manager.deleteDeck(d) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header Actions

    private var headerActions: some View {
        HStack(spacing: 12) {
            actionButton("New Deck", icon: "plus.rectangle.on.rectangle", color: .blue) {
                showingCreate = true
            }

            Button {
                showingAIGenerate = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    Text("AI Generate")
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Sheet

    private var createDeckSheet: some View {
        NavigationStack {
            Form {
                Section("Deck Title") {
                    TextField("e.g. Q4 Sales Pitch", text: $newDeckTitle)
                }
            }
            .navigationTitle("New Presentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        newDeckTitle = ""
                        showingCreate = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let title = newDeckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.createDeck(title: title.isEmpty ? "Untitled Deck" : title)
                        newDeckTitle = ""
                        showingCreate = false
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - AI Generate Sheet

    private var aiGenerateSheet: some View {
        NavigationStack {
            Form {
                Section("Describe your presentation") {
                    TextEditor(text: $aiPrompt)
                        .frame(minHeight: 100)
                }
                if let err = generationError {
                    Section {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("AI Presentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        aiPrompt = ""
                        generationError = nil
                        showingAIGenerate = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Button("Generate") {
                            generateFromAI()
                        }
                        .bold()
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - AI Generation

    private func generateFromAI() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        isGenerating = true
        generationError = nil

        Task {
            do {
                let systemPrompt = """
You are a presentation builder. Given a topic, generate a JSON slide deck with this exact structure:
{
  "title": "Deck Title",
  "slides": [
    {"title": "Slide Title", "background": "1E3A5F", "elements": [
      {"kind": "text", "text": "Content here", "x": 195, "y": 150, "width": 350, "height": 80, "fontSize": 32, "textColor": "FFFFFF"}
    ]}
  ]
}
Return ONLY valid JSON. No markdown, no extra text. Generate 4-6 slides.
"""
                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: systemPrompt)
                let deck = try parseDeckFromAI(result, title: prompt.prefix(40).description)
                await MainActor.run {
                    manager.addDeck(deck)
                    aiPrompt = ""
                    isGenerating = false
                    showingAIGenerate = false
                }
            } catch {
                await MainActor.run {
                    generationError = "Generation failed: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }

    private func parseDeckFromAI(_ json: String, title: String) throws -> SlideDeck {
        // Extract JSON from response (in case it has surrounding text)
        let cleaned = extractJSON(from: json)
        guard let data = cleaned.data(using: .utf8) else { throw AIParseError.invalidData }

        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let deckTitle = raw?["title"] as? String ?? title
        let rawSlides = raw?["slides"] as? [[String: Any]] ?? []

        var deck = SlideDeck(title: deckTitle)
        deck.slides = rawSlides.enumerated().map { idx, rs in
            var slide = Slide(title: rs["title"] as? String ?? "Slide \(idx + 1)")
            slide.backgroundColorHex = rs["background"] as? String ?? "1E3A5F"
            let rawElements = rs["elements"] as? [[String: Any]] ?? []
            slide.elements = rawElements.compactMap { re -> SlideElement? in
                guard let kind = re["kind"] as? String else { return nil }
                var el = SlideElement(kind: SlideElement.ElementKind(rawValue: kind) ?? .text)
                el.x = re["x"] as? Double ?? 195
                el.y = re["y"] as? Double ?? 200
                el.width = re["width"] as? Double ?? 350
                el.height = re["height"] as? Double ?? 60
                el.text = re["text"] as? String ?? ""
                el.fontSize = re["fontSize"] as? Double ?? 28
                el.textColor = re["textColor"] as? String ?? "FFFFFF"
                el.fillColor = re["fillColor"] as? String ?? "3B82F6"
                return el
            }
            return slide
        }
        if deck.slides.isEmpty {
            deck.slides = [Slide.blank(title: "Slide 1")]
        }
        return deck
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }
}

enum AIParseError: Error {
    case invalidData, missingField
}

// MARK: - Deck Card

private struct DeckCard: View {
    let deck: SlideDeck
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail of first slide
            if let first = deck.slides.first {
                SlideThumbnailView(slide: first)
                    .frame(height: 90)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(height: 90)
                    .overlay(
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .foregroundColor(.blue.opacity(0.5))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(deck.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Label("\(deck.slideCount) slides", systemImage: "rectangle.stack")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(deck.updatedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
