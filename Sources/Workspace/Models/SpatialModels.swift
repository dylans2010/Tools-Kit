import Foundation

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
    var position: CGPoint
    var size: CGSize
    var properties: [String: String] = [:]
}

enum ElementType: String, Codable {
    case stickyNote = "stickyNote"
    case shape = "shape"
    case text = "text"
    case image = "image"
    case asset = "asset"
}

// Extension to help with CGPoint/CGSize codable if needed,
// though they often are available or can be shimmed.
extension CGPoint {
    var dictionaryRepresentation: [String: Double] {
        ["x": Double(x), "y": Double(y)]
    }
}
