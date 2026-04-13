import Foundation

struct NotebookPage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = "Untitled Page"
    var content: String = ""
    var attachments: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
