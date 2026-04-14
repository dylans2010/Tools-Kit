import Foundation

struct EmailMessage: Identifiable, Hashable {
    let id = UUID()
    var uid: Int
    var subject: String
    var sender: String
    var date: Date
    var preview: String
    var isRead: Bool
    var body: String?
    var htmlBody: String? = nil
    var attachments: [EmailAttachment] = []
}

struct EmailAttachment: Identifiable, Hashable {
    let id = UUID()
    var filename: String
    var mimeType: String
    var data: Data
}
