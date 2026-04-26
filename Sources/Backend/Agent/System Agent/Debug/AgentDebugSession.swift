import Foundation

struct AgentDebugSession: Codable {
    let id: UUID
    var startedAt: Date
    var notes: [String]

    init(id: UUID = UUID(), startedAt: Date = Date(), notes: [String] = []) {
        self.id = id
        self.startedAt = startedAt
        self.notes = notes
    }

    mutating func append(note: String) {
        notes.append(note)
    }
}
