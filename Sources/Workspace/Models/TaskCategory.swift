import Foundation

struct TaskCategory: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String = "3B82F6") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}
