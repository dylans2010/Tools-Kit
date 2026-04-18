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

    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: 16) {
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
                } header: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Slides")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Button {
                                showingAIGenerate = true
                            } label: {
                                Label("Generate", systemImage: "sparkles")
                            }
                            .buttonStyle(.bordered)
                            Button {
                                showingCreate = true
                            } label: {
                                Label("New", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Text("Prompt-to-deck generation with structured slides and speaker notes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .bottom)
                }
            }
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
    }

    private var aiGenerateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe your presentation goal")
                    .font(.headline)
                TextEditor(text: $aiPrompt)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            }
            .padding(16)
            .navigationTitle("AI Presentation")
        }
    }

    private func generateFromAI() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                // The deck payload is validated against a strict JSON schema before rendering.
                let payload = try await manager.generateDeckFromPrompt(prompt)
                var deck = SlideDeck(title: payload.title)
                deck.slides = payload.slides.enumerated().map { index, item in
                    var slide = Slide(title: item.title.isEmpty ? "Slide \(index + 1)" : item.title)
                    slide.backgroundColorHex = item.background
                    slide.elements = item.elements.map { element in
                        let aiKind = SlideElement.ElementKind(rawValue: element.kind)
                        let resolvedKind = aiKind ?? .text
                        // Keep a visible diagnostic when AI returns unsupported element kinds.
                        if aiKind == nil {
                            print("SlidesHomeView: unsupported AI element kind \(element.kind), falling back to text")
                        }
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
                    aiError = "Could not decode AI deck. Refine prompt and retry."
                    aiLoading = false
                }
            }
        }
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
