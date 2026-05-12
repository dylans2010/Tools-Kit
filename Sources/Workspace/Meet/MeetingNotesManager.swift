import Foundation

@MainActor
final class MeetingNotesManager: ObservableObject {
    static let shared = MeetingNotesManager()

    @Published private(set) var notesBySession: [String: String] = [:]

    private let storageKey = "meet_notes_by_session"

    init() {
        loadPersistedNotes()
    }

    func notes(for sessionID: String) -> String {
        notesBySession[sessionID] ?? ""
    }

    func setNotes(_ notes: String, for sessionID: String) {
        notesBySession[sessionID] = notes
        persistNotes()
    }

    func summarize(notes: String) async throws -> String {
        try await AIService.shared.processText(
            prompt: "Summarize these meeting notes in concise bullet points and include decisions made:\n\n\(notes)",
            systemPrompt: "You are an expert meeting assistant."
        )
    }

    func extractActionItems(notes: String) async throws -> String {
        let schema = """
        {
          "type": "object",
          "properties": {
            "action_items": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "task": { "type": "string" },
                  "owner": { "type": "string" },
                  "due": { "type": "string" }
                },
                "required": ["task"]
              }
            }
          },
          "required": ["action_items"]
        }
        """
        return try await AIService.shared.generateStructuredJSON(
            prompt: "Extract action items from these meeting notes. Return only factual items. Notes:\n\n\(notes)",
            jsonSchema: schema,
            systemPrompt: "You extract concrete action items from meeting notes and return strict JSON."
        )
    }

    func rewrite(notes: String) async throws -> String {
        try await AIService.shared.processText(
            prompt: "Rewrite these meeting notes to be clear, well-structured, and concise while preserving meaning:\n\n\(notes)",
            systemPrompt: "You are an expert technical editor."
        )
    }

    private func loadPersistedNotes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        notesBySession = decoded
    }

    private func persistNotes() {
        guard let data = try? JSONEncoder().encode(notesBySession) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
