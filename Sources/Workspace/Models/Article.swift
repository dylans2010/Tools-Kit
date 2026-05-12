import Foundation

struct Article: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var summary: String = ""
    var content: String = ""
    var imageURL: String? = nil
    var language: String = "en"
    var sourceURL: String = ""
    var pageID: Int? = nil
    var savedAt: Date = Date()
}
