import Foundation

struct Notebook: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = "Untitled Notebook"
    var folders: [NotebookFolder] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
