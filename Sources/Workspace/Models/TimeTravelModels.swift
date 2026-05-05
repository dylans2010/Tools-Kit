import Foundation

struct WorkspaceSnapshot: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var message: String
    var entityType: String // "Note", "Task", "Space", etc.
    var entityID: UUID
    var data: Data // The serialized state
    var author: String
}

struct TimeTravelChange: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var entityType: String
    var entityID: UUID
    var action: String // "created", "updated", "deleted"
    var previousValue: Data?
    var newValue: Data?
    var userID: UUID
}
