import Foundation

public struct SlideDeck: Codable, Identifiable, Equatable {
    public var id: UUID = UUID()
    var title: String = "Untitled Deck"
    var theme: String = "default"
    var slides: [Slide] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var slideCount: Int { slides.count }

    static func empty(title: String = "Untitled Deck") -> SlideDeck {
        SlideDeck(title: title, slides: [Slide.blank(title: "Slide 1")])
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case theme
        case slides
        case createdAt
        case updatedAt
    }

    public init(
        id: UUID = UUID(),
        title: String = "Untitled Deck",
        theme: String = "default",
        slides: [Slide] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.theme = theme
        self.slides = slides
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled Deck"
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "default"
        slides = try container.decodeIfPresent([Slide].self, forKey: .slides) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}
