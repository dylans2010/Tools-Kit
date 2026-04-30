import Foundation

struct NotebookPage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = "Untitled Page"
    var content: String = ""
    var blocks: [NotebookBlock] = []
    var attachments: [String] = []
    var history: [NotebookVersion] = []
    var backlinks: [NotebookBacklink] = []
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
