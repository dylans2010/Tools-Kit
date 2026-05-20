import Foundation

struct Notebook: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = "Untitled Notebook"
    var folders: [NotebookFolder] = []
    var iconName: String = "book.closed"
    var colorHex: String = "#4F46E5"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
