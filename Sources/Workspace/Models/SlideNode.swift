import Foundation
import CoreGraphics

/// Hierarchical scene graph node for slides, enabling nested layers and transformations.
struct SlideNode: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = "Layer"
    var kind: NodeKind
    var children: [SlideNode] = []

    var position: CGPoint = .zero
    var size: CGSize = CGSize(width: 100, height: 100)
    var rotation: Double = 0
    var scale: Double = 1.0
    var opacity: Double = 1.0
    var zIndex: Int = 0

    // Properties for specific kinds
    var text: String?
    var backgroundColorHex: String?
    var assetID: UUID?

    enum NodeKind: String, Codable {
        case group, text, shape, image, componentInstance
    }
}
