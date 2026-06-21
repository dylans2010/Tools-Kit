import Foundation

struct SpeechHistorySession: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var messages: [SpeechMessage]
}

class SpeechHistoryManager: ObservableObject {
    static let shared = SpeechHistoryManager()

    @Published var history: [SpeechHistorySession] = []
    private let key = "speech_history_sessions"

    private init() {
        loadHistory()
    }

    func saveSession(_ session: SpeechHistorySession) {
        if let index = history.firstIndex(where: { $0.id == session.id }) {
            var updated = session
            // Keep original creation date
            let originalDate = history[index].createdAt
            updated = SpeechHistorySession(id: session.id, title: session.title, createdAt: originalDate, messages: session.messages)
            history[index] = updated
        } else {
            history.insert(session, at: 0)
        }
        persist()
    }

    func deleteSession(id: UUID) {
        history.removeAll { $0.id == id }
        persist()
    }

    func renameSession(id: UUID, newTitle: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].title = newTitle
            persist()
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SpeechHistorySession].self, from: data) else { return }
        history = decoded
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
