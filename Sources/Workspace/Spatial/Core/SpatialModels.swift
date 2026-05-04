import Foundation
import CoreGraphics

struct SpatialCanvas: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [CanvasItem]
}

struct CanvasItem: Identifiable, Codable {
    let id: UUID
    var type: ItemType
    var position: CGPoint
    var size: CGSize
    var content: String

    enum ItemType: String, Codable {
        case note, image, task, file, whiteboard
    }
}
