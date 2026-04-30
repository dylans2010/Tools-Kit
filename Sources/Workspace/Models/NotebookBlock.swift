import Foundation

struct NotebookBlock: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: BlockKind
    var content: String = ""
    var metadata: [String: String] = [:]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    enum BlockKind: String, Codable, CaseIterable {
        case text, code, database, toggle, embed, widget
    }
}

struct NotebookVersion: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var blocks: [NotebookBlock]
    var author: String
}

struct NotebookBacklink: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var sourcePageID: UUID
    var sourcePageTitle: String
    var context: String
}
