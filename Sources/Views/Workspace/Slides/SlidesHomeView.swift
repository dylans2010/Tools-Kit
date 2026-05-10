import SwiftUI

struct SlidesHomeView: View {
    @StateObject private var manager = SlideDecksManager.shared
    @State private var showingCreate = false
    @State private var deckTitle = ""

    var body: some View {
        List {
            Section("Decks") {
                if manager.decks.isEmpty {
                    ContentUnavailableView("No decks yet", systemImage: "rectangle.on.rectangle", description: Text("Create one manually or generate with AI."))
                } else {
                    ForEach(manager.decks) { deck in
                        NavigationLink {
                            SlideEditorView(deck: deck, manager: manager)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(deck.title)
                                    .font(.headline)
                                Text("\(deck.slideCount) slides")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.deleteDeck(manager.decks[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Slides")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink {
                    AIGenerateSlides()
                } label: {
                    Label("AI Generate", systemImage: "sparkles")
                }
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Create Deck", isPresented: $showingCreate) {
            TextField("Deck title", text: $deckTitle)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let title = deckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                manager.createDeck(title: title.isEmpty ? "Untitled Deck" : title)
                deckTitle = ""
            }
        }
    }
}
