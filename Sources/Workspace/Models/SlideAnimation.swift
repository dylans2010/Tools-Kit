import Foundation

struct SlideAnimation: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var type: AnimationType
    var duration: Double = 0.5
    var delay: Double = 0
    var easing: String = "easeInOut"

    enum AnimationType: String, Codable, CaseIterable, Sendable {
        case fadeIn, slideIn, zoomIn, rotate
    }
}

struct SlideKeyframe: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var time: Double
    var value: Double
    var property: String
}
