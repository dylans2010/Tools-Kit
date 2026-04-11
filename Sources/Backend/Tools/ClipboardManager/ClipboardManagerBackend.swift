import Foundation
import SwiftUI

struct ClipboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isFavorite: Bool = false
}

class ClipboardManagerBackend: ObservableObject {
    @Published var history: [ClipboardEntry] = []

    private let savePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("clipboard_history.json")

    init() {
        loadHistory()
    }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        addEntry(text)
    }

    func pasteFromClipboard() -> String {
        let content = UIPasteboard.general.string ?? ""
        if !content.isEmpty {
            addEntry(content)
        }
        return content
    }

    private func addEntry(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Avoid duplicate consecutive entries
        if let last = history.first, last.content == trimmed { return }

        let entry = ClipboardEntry(id: UUID(), content: trimmed, timestamp: Date())
        history.insert(entry, at: 0)

        if history.count > 50 {
            history.removeLast()
        }
        saveHistory()
    }

    func deleteEntry(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    func toggleFavorite(_ entry: ClipboardEntry) {
        if let index = history.firstIndex(where: { $0.id == entry.id }) {
            history[index].isFavorite.toggle()
            saveHistory()
        }
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: savePath)
        } catch {
            print("Error saving clipboard history: \(error)")
        }
    }

    private func loadHistory() {
        do {
            if FileManager.default.fileExists(atPath: savePath.path) {
                let data = try Data(contentsOf: savePath)
                history = try JSONDecoder().decode([ClipboardEntry].self, from: data)
            }
        } catch {
            print("Error loading clipboard history: \(error)")
        }
    }
}
