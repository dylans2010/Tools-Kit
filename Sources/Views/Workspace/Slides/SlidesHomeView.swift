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

    var body: some View {
        List {
            Section("Overview") {
                HStack(spacing: 12) {
                    SlideStatLabel(label: "Decks", value: "\(manager.decks.count)")
                    SlideStatLabel(label: "Slides", value: "\(manager.decks.reduce(0) { $0 + $1.slideCount })")
                    SlideStatLabel(label: "Status", value: manager.decks.isEmpty ? "Create" : "Ready")
                }
            }

            if manager.decks.isEmpty {
                ContentUnavailableView {
                    Label("No Presentations", systemImage: "rectangle.on.rectangle.angled")
                } description: {
                    Text("Create a deck manually or generate one with AI.")
                } actions: {
                    Button("Create Deck") { showingCreate = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Section("Your Decks") {
                    ForEach(manager.decks) { deck in
                        NavigationLink {
                            SlideEditorView(deck: deck, manager: manager)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(deck.title)
                                        .font(.body.weight(.semibold))
                                    Text("\(deck.slideCount) slides")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "rectangle.on.rectangle")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                manager.deleteDeck(deck)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Slides")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAIGenerate = true } label: {
                    Image(systemName: "sparkles")
                }
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) { createDeckSheet }
        .sheet(isPresented: $showingAIGenerate) { aiGenerateSheet }
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
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var aiGenerateSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe your presentation in plain language…", text: $aiPrompt, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("AI Presentation")
                } footer: {
                    Text("Short requests are fine — AI will infer structure, content, and design.")
                }

                Section("Quick Presets") {
                    HStack(spacing: 8) {
                        Button("Pitch") { aiPrompt = "Create a startup investor deck from my idea." }
                            .buttonStyle(.bordered)
                        Button("Launch") { aiPrompt = "Create a product launch presentation." }
                            .buttonStyle(.bordered)
                        Button("Class") { aiPrompt = "Create a teaching deck for beginners." }
                            .buttonStyle(.bordered)
                    }
                    HStack(spacing: 8) {
                        Button("Workshop") { aiPrompt = "Create a workshop deck with exercises and discussion prompts." }
                            .buttonStyle(.bordered)
                        Button("Review") { aiPrompt = "Create a quarterly business review presentation." }
                            .buttonStyle(.bordered)
                    }
                }

                Section {
                    if aiLoading {
                        ProgressView("Generating presentation…")
                    } else if let aiError {
                        Label(aiError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Generate", action: generateFromAI)
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                }
            }
            .navigationTitle("AI Presentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAIGenerate = false
                        aiPrompt = ""
                        aiError = nil
                    }
                }
            }
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
}

private struct SlideStatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
