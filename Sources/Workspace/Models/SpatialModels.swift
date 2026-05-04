import Foundation
import CoreGraphics

struct SpatialCanvas: Identifiable, Codable {
    let id: UUID
    var name: String
    var nodes: [SpatialNode]
    var lastModified: Date
}

struct SpatialNode: Identifiable, Codable {
    let id: UUID
    var title: String
    var type: NodeType
    var position: CGPoint
    var entityID: UUID?

    enum NodeType: String, Codable {
        case note, task, file, meeting
    }
}
