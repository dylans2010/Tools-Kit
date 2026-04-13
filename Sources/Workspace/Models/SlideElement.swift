import Foundation

struct SlideElement: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: ElementKind
    var x: Double = 100
    var y: Double = 100
    var width: Double = 200
    var height: Double = 60
    var zIndex: Int = 0

    // Text
    var text: String = "Text"
    var fontSize: Double = 24
    var fontWeight: String = "regular"
    var textColor: String = "FFFFFF"
    var textAlignment: String = "center"

    // Image
    var imageData: Data?

    // Shape
    var shapeKind: ShapeKind = .rectangle
    var fillColor: String = "3B82F6"
    var strokeColor: String = "FFFFFF"
    var strokeWidth: Double = 0
    var cornerRadius: Double = 8

    enum ElementKind: String, Codable, CaseIterable {
        case text, image, shape
    }

    enum ShapeKind: String, Codable, CaseIterable {
        case rectangle, circle, triangle
        var displayName: String {
            switch self {
            case .rectangle: return "Rectangle"
            case .circle: return "Circle"
            case .triangle: return "Triangle"
            }
        }
    }
}
