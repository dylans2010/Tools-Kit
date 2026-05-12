import Foundation

struct TaskCategory: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String = "#007AFF") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}
