import Foundation

public struct Slide: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID = UUID()
    var type: String = "title"
    var title: String = "New Slide"
    var layout: String = "title"
    var backgroundColorHex: String = "1E3A5F"
    var backgroundImageData: Data?
    var elements: [SlideElement] = []
    var metadata: [String: String] = [:]
    var bullets: [String] = []
    var speakerNotes: String?

    static func blank(title: String = "New Slide") -> Slide {
        Slide(title: title)
    }

    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case type
        case title
        case layout
        case backgroundColorHex
        case backgroundImageData
        case elements
        case metadata
        case bullets
        case speakerNotes
    }

    public init(
        id: UUID = UUID(),
        type: String = "title",
        title: String = "New Slide",
        layout: String = "title",
        backgroundColorHex: String = "1E3A5F",
        backgroundImageData: Data? = nil,
        elements: [SlideElement] = [],
        metadata: [String: String] = [:],
        bullets: [String] = [],
        speakerNotes: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.layout = layout
        self.backgroundColorHex = backgroundColorHex
        self.backgroundImageData = backgroundImageData
        self.elements = elements
        self.metadata = metadata
        self.bullets = bullets
        self.speakerNotes = speakerNotes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "title"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "New Slide"
        layout = try container.decodeIfPresent(String.self, forKey: .layout) ?? "title"
        backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "1E3A5F"
        backgroundImageData = try container.decodeIfPresent(Data.self, forKey: .backgroundImageData)
        elements = try container.decodeIfPresent([SlideElement].self, forKey: .elements) ?? []
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        bullets = try container.decodeIfPresent([String].self, forKey: .bullets) ?? []
        speakerNotes = try container.decodeIfPresent(String.self, forKey: .speakerNotes)
    }
}
