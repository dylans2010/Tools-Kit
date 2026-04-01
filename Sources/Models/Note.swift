import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var folder: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var versionHistory: [NoteVersion]

    init(id: UUID = UUID(), title: String = "Untitled", content: String = "", folder: String = "General", tags: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date(), versionHistory: [NoteVersion] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.versionHistory = versionHistory
    }
}

struct NoteVersion: Identifiable, Codable, Equatable {
    var id: UUID
    var content: String
    var timestamp: Date

    init(id: UUID = UUID(), content: String, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}
