import Foundation

struct Slide: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = "New Slide"
    var backgroundColorHex: String = "1E3A5F"
    var backgroundImageData: Data?
    var elements: [SlideElement] = []

    static func blank(title: String = "New Slide") -> Slide {
        Slide(title: title)
    }
}
