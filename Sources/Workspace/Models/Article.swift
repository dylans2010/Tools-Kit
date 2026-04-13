import Foundation

struct Article: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = ""
    var summary: String = ""
    var content: String = ""
    var imageURL: String? = nil
    var language: String = "en"
    var sourceURL: String = ""
    var savedAt: Date = Date()
}
