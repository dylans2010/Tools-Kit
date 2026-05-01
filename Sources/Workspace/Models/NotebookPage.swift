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

    init(
        id: UUID = UUID(),
        title: String = "Untitled Page",
        content: String = "",
        blocks: [NotebookBlock] = [],
        attachments: [String] = [],
        history: [NotebookVersion] = [],
        backlinks: [NotebookBacklink] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.blocks = blocks
        self.attachments = attachments
        self.history = history
        self.backlinks = backlinks
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
