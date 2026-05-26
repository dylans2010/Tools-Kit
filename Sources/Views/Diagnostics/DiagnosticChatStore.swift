import Foundation
import Combine

struct DiagnosticChatSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "New Diagnostic Session", messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

final class DiagnosticChatStore: ObservableObject {
    static let shared = DiagnosticChatStore()

    @Published var sessions: [DiagnosticChatSession] = []

    private let storageKey = "diagnostic_chat_sessions"

    private init() {
        loadSessions()
    }

    func saveSession(_ session: DiagnosticChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            sessions[index].updatedAt = Date()
        } else {
            sessions.insert(session, at: 0)
        }
        persist()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        persist()
    }

    func updateTitle(id: UUID, title: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].title = title
            sessions[index].updatedAt = Date()
            persist()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DiagnosticChatSession].self, from: data) {
            self.sessions = decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }
}
