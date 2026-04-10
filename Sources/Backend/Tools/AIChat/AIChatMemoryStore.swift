import Foundation
import CoreML

struct ChatMemoryItem: Identifiable, Codable {
    let id: UUID
    let value: String
    let createdAt: Date

    init(id: UUID = UUID(), value: String, createdAt: Date = Date()) {
        self.id = id
        self.value = value
        self.createdAt = createdAt
    }
}

final class AIChatMemoryStore: ObservableObject {
    static let shared = AIChatMemoryStore()

    @Published private(set) var memories: [ChatMemoryItem] = []
    private let key = "ai_chat_memories"
    private let config = MLModelConfiguration()

    private init() {
        _ = config
        load()
    }

    func ingestUserMessage(_ text: String, sensitivity: Double) {
        let important = extractImportantDetails(from: text, sensitivity: sensitivity)
        guard !important.isEmpty else { return }
        for detail in important where !memories.contains(where: { $0.value.caseInsensitiveCompare(detail) == .orderedSame }) {
            memories.insert(ChatMemoryItem(value: detail), at: 0)
        }
        if memories.count > 100 {
            memories = Array(memories.prefix(100))
        }
        save()
    }

    func contextSnippet(limit: Int = 8) -> String {
        let top = memories.prefix(limit).map { "- \($0.value)" }.joined(separator: "\n")
        return top.isEmpty ? "" : "User memory:\n\(top)"
    }

    func delete(_ item: ChatMemoryItem) {
        memories.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        memories = []
        save()
    }

    private func extractImportantDetails(from text: String, sensitivity: Double) -> [String] {
        let lines = text
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let triggerWords = ["i am", "i'm", "my", "prefer", "allergic", "timezone", "name is", "work as", "goal"]
        let minLength = sensitivity > 0.8 ? 20 : 12

        return lines.filter { line in
            line.count >= minLength && triggerWords.contains(where: { line.lowercased().contains($0) })
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ChatMemoryItem].self, from: data) else { return }
        memories = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(memories) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
