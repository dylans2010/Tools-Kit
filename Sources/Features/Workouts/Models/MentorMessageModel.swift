import Foundation

enum MentorMessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct MentorMessageModel: Identifiable, Codable {
    var id: UUID
    var role: MentorMessageRole
    var text: String
    var createdAt: Date
    var imageHint: String?

    init(
        id: UUID = UUID(),
        role: MentorMessageRole,
        text: String,
        createdAt: Date = Date(),
        imageHint: String? = nil
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.imageHint = imageHint
    }
}
