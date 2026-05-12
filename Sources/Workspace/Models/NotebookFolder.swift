import Foundation

struct NotebookFolder: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String = "New Folder"
    var pages: [NotebookPage] = []
    var createdAt: Date = Date()
}
