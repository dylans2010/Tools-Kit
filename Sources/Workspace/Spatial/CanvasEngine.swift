import Foundation
import CoreGraphics

/// Engine for handling spatial canvas logic.
final class CanvasEngine: ObservableObject {
    @Published var canvas: SpatialCanvas

    init(canvas: SpatialCanvas) {
        self.canvas = canvas
    }

    func addElement(_ type: ElementType, at position: CGPoint) {
        var element = SpatialElement(
            type: type,
            x: Double(position.x),
            y: Double(position.y),
            width: 150,
            height: 150,
            properties: ["color": "yellow", "text": "New Note"]
        )

        if canvas.layers.isEmpty {
            canvas.layers.append(SpatialLayer(name: "Base Layer"))
        }

        canvas.layers[0].elements.append(element)
        save()
    }

    func updateElementPosition(_ elementID: UUID, to newPosition: CGPoint) {
        for i in 0..<canvas.layers.count {
            if let j = canvas.layers[i].elements.firstIndex(where: { $0.id == elementID }) {
                canvas.layers[i].elements[j].position = newPosition
                break
            }
        }
        save()
    }

    private func save() {
        try? UnifiedDataStore.shared.saveSpatialCanvas(canvas)
    }
}

final class WhiteboardService {
    nonisolated(unsafe) static let shared = WhiteboardService()
    private init() {}

    func createNewCanvas(name: String) -> SpatialCanvas {
        let canvas = SpatialCanvas(name: name, layers: [SpatialLayer(name: "Layer 1")])
        try? UnifiedDataStore.shared.saveSpatialCanvas(canvas)
        return canvas
    }
}
