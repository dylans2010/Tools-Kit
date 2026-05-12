import Foundation

enum MentorMessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

struct MentorMessageModel: Identifiable, Codable, Sendable {
    var id: UUID
    var role: MentorMessageRole
    var text: String
    var createdAt: Date
    var imageHint: String?
    var insights: [String]
    var recommendations: [String]

    init(
        id: UUID = UUID(),
        role: MentorMessageRole,
        text: String,
        createdAt: Date = Date(),
        imageHint: String? = nil,
        insights: [String] = [],
        recommendations: [String] = []
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.imageHint = imageHint
        self.insights = insights
        self.recommendations = recommendations
    }

    private enum CodingKeys: String, CodingKey, Sendable {
        case id, role, text, createdAt, imageHint, insights, recommendations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        role = try container.decodeIfPresent(MentorMessageRole.self, forKey: .role) ?? .assistant
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        imageHint = try container.decodeIfPresent(String.self, forKey: .imageHint)
        insights = try container.decodeIfPresent([String].self, forKey: .insights) ?? []
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
    }
}
