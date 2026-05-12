import Foundation

struct TimeTravelChange: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var timestamp: Date
    var entityType: String
    var entityID: UUID
    var action: String // "created", "updated", "deleted"
    var previousValue: Data?
    var newValue: Data?
    var userID: UUID
}
