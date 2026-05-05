import Foundation
import CoreGraphics

struct SpatialCanvas: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var layers: [SpatialLayer] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct SpatialLayer: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var isVisible: Bool = true
    var elements: [SpatialElement] = []
}

struct SpatialElement: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ElementType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var properties: [String: String] = [:]

    var position: CGPoint {
        get { CGPoint(x: x, y: y) }
        set { x = Double(newValue.x); y = Double(newValue.y) }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
        set { width = Double(newValue.width); height = Double(newValue.height) }
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, x, y, width, height, properties
    }
}

enum ElementType: String, Codable {
    case stickyNote = "stickyNote"
    case shape = "shape"
    case text = "text"
    case image = "image"
    case asset = "asset"
}
