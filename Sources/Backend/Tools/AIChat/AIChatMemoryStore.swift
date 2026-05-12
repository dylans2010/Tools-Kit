import Foundation
import NaturalLanguage

struct ChatMemoryItem: Identifiable, Codable, Sendable {
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
    nonisolated(unsafe) static let shared = AIChatMemoryStore()

    @Published private(set) var memories: [ChatMemoryItem] = []
    private let key = "ai_chat_memories"

    private init() {
        load()
    }

    func ingestUserMessage(_ text: String, sensitivity: Double) {
        let important = extractImportantDetails(from: text, sensitivity: sensitivity)
        guard !important.isEmpty else { return }

        for detail in important {
            let exists = memories.contains {
                $0.value.caseInsensitiveCompare(detail) == .orderedSame ||
                detail.localizedCaseInsensitiveContains($0.value)
            }
            if !exists {
                memories.insert(ChatMemoryItem(value: detail), at: 0)
            }
        }

        if memories.count > 100 {
            memories = Array(memories.prefix(100))
        }
        save()
    }

    func contextSnippet(limit: Int = 12) -> String {
        let top = memories.prefix(limit).map { "- \($0.value)" }.joined(separator: "\n")
        return top.isEmpty ? "" : "Relevant User Facts & History:\n\(top)"
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
        var findings: [String] = []
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        // 1. Named Entity Recognition (People, Places, Orgs)
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, [.personalName, .placeName, .organizationName].contains(tag) {
                let entity = String(text[range])
                if entity.count > 2 {
                    findings.append("Mentioned \(tag.rawValue.replacingOccurrences(of: "Name", with: "")): \(entity)")
                }
            }
            return true
        }

        // 2. Intent & Preference Extraction (Heuristic-based)
        let lines = text.split(separator: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let triggers = ["i am", "i'm", "my", "prefer", "love", "hate", "allergic", "live in", "work as", "studied", "goal is"]

        for line in lines {
            let lowerLine = line.lowercased()
            if triggers.contains(where: { lowerLine.contains($0) }) {
                if line.count > 10 && line.count < 150 {
                    findings.append(line)
                }
            }
        }

        return Array(Set(findings))
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
