import Foundation
import Combine

final class SlideDecksManager: ObservableObject {
    static let shared = SlideDecksManager()

    @Published var decks: [SlideDeck] = []

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Slides", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func deckURL(for id: UUID) -> URL {
        saveDir.appendingPathComponent("\(id.uuidString).json")
    }

    private init() {
        load()
    }

    // MARK: - CRUD

    func createDeck(title: String = "Untitled Deck") -> SlideDeck {
        let deck = SlideDeck.empty(title: title)
        decks.insert(deck, at: 0)
        save(deck)
        return deck
    }

    func updateDeck(_ deck: SlideDeck) {
        if let idx = decks.firstIndex(where: { $0.id == deck.id }) {
            var updated = deck
            updated.updatedAt = Date()
            decks[idx] = updated
            save(updated)
        }
    }

    func deleteDeck(_ deck: SlideDeck) {
        decks.removeAll { $0.id == deck.id }
        try? FileManager.default.removeItem(at: deckURL(for: deck.id))
    }

    func addDeck(_ deck: SlideDeck) {
        decks.insert(deck, at: 0)
        save(deck)
    }

    // MARK: - Persistence

    private func save(_ deck: SlideDeck) {
        do {
            let data = try JSONEncoder().encode(deck)
            try data.write(to: deckURL(for: deck.id))
        } catch {
            print("SlideDecksManager: save error \(error)")
        }
    }

    private func load() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: saveDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        decks = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> SlideDeck? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SlideDeck.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
