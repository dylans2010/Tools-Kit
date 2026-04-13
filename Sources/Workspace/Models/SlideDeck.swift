import Foundation

struct SlideDeck: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = "Untitled Deck"
    var slides: [Slide] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var slideCount: Int { slides.count }

    static func empty(title: String = "Untitled Deck") -> SlideDeck {
        SlideDeck(title: title, slides: [Slide.blank(title: "Slide 1")])
    }
}
