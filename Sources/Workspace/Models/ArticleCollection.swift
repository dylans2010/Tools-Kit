import Foundation

struct ArticleCollection: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "folder"
    var colorHex: String = "3B82F6"
    var articles: [Article] = []
    var createdAt: Date = Date()
}
