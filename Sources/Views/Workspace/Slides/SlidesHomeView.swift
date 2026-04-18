import SwiftUI

struct SlidesHomeView: View {
    @StateObject private var manager = SlideDecksManager.shared
    @State private var showingCreate = false
    @State private var showingAIGenerate = false
    @State private var newDeckTitle = ""
    @State private var aiPrompt = ""
    @State private var aiError: String?
    @State private var aiLoading = false
    @State private var deckToDelete: SlideDeck?
    @State private var showDeleteConfirm = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard
                if manager.decks.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.on.rectangle.angled",
                        title: "No Presentations",
                        message: "Create a deck manually or generate one from AI.",
                        action: { showingCreate = true },
                        actionLabel: "Create Deck"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
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
                }
            }
            .padding(16)
        }
        .navigationTitle("Slides")
        .sheet(isPresented: $showingCreate) { createDeckSheet }
        .sheet(isPresented: $showingAIGenerate) { aiGenerateSheet }
        .confirmationDialog("Delete \"\(deckToDelete?.title ?? "")\"?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let deckToDelete { manager.deleteDeck(deckToDelete) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var heroCard: some View {
        WorkspaceSurfaceCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Slides")
                        .font(.title3.bold())
                    Text("iOS-first editor with natural-language AI generation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingAIGenerate = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var createDeckSheet: some View {
        NavigationStack {
            Form {
                Section("Deck Title") {
                    TextField("e.g. Q4 Business Review", text: $newDeckTitle)
                }
            }
            .navigationTitle("New Presentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newDeckTitle = ""
                        showingCreate = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let title = newDeckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.createDeck(title: title.isEmpty ? "Untitled Deck" : title)
                        newDeckTitle = ""
                        showingCreate = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var aiGenerateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe your presentation in plain language")
                    .font(.headline)
                Text("No need for rigid structure; short requests are supported.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $aiPrompt)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    aiPresetButton("Pitch", icon: "briefcase.fill", prompt: "Create a startup investor deck from my idea.")
                    aiPresetButton("Launch", icon: "megaphone.fill", prompt: "Create a product launch presentation.")
                    aiPresetButton("Class", icon: "graduationcap.fill", prompt: "Create a teaching deck for beginners.")
                }

                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                HStack {
                    Button("Generate", action: generateFromAI)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                    Spacer()
                    Button("Cancel") {
                        showingAIGenerate = false
                        aiPrompt = ""
                        aiError = nil
                    }
                    .buttonStyle(.bordered)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("AI Presentation")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func generateFromAI() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let payload = try await manager.generateDeckFromPrompt(prompt)
                var deck = SlideDeck(title: payload.title)
                deck.slides = payload.slides.enumerated().map { index, item in
                    var slide = Slide(title: item.title.isEmpty ? "Slide \(index + 1)" : item.title)
                    slide.backgroundColorHex = item.background
                    slide.elements = item.elements.map { element in
                        let aiKind = SlideElement.ElementKind(rawValue: element.kind)
                        let resolvedKind = aiKind ?? .text
                        var model = SlideElement(kind: resolvedKind)
                        model.text = element.text
                        model.x = element.x
                        model.y = element.y
                        model.width = element.width
                        model.height = element.height
                        model.fontSize = element.fontSize
                        model.textColor = element.textColor
                        model.fillColor = element.fillColor
                        return model
                    }
                    return slide
                }
                if deck.slides.isEmpty { deck.slides = [Slide.blank(title: "Slide 1")] }
                await MainActor.run {
                    manager.addDeck(deck)
                    aiPrompt = ""
                    aiLoading = false
                    showingAIGenerate = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Could not generate this deck yet. Try any plain-language goal and AI will infer structure."
                    aiLoading = false
                }
            }
        }
    }

    private func aiPresetButton(_ title: String, icon: String, prompt: String) -> some View {
        Button {
            aiPrompt = prompt
            showingAIGenerate = true
        } label: {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }
}

private struct DeckCard: View {
    let deck: SlideDeck
    let onDelete: () -> Void

    var body: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                if let first = deck.slides.first {
                    SlideThumbnailView(slide: first)
                        .frame(height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deck.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(deck.slideCount) slides")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
