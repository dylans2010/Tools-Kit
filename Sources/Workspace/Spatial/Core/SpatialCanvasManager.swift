import Foundation
import Combine

/// Manages the state and persistence of the spatial workspace.
final class SpatialCanvasManager: ObservableObject {
    static let shared = SpatialCanvasManager()

    @Published var currentCanvas: SpatialCanvas
    private let storageFile = "spatial_workspace.json"

    private init() {
        self.currentCanvas = SpatialCanvas(id: UUID(), name: "Main Workspace", items: [])
        load()
    }

    func addItem(_ type: CanvasItem.ItemType, at position: CGPoint) {
        let newItem = CanvasItem(
            id: UUID(),
            type: type,
            position: position,
            size: CGSize(width: 200, height: 200),
            content: "New \(type.rawValue)"
        )
        currentCanvas.items.append(newItem)
        save()
    }

    func updateItem(_ item: CanvasItem) {
        if let index = currentCanvas.items.firstIndex(where: { $0.id == item.id }) {
            currentCanvas.items[index] = item
            save()
        }
    }

    private func save() {
        try? WorkspacePersistence.shared.save(currentCanvas, to: storageFile)
    }

    private func load() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            if let loaded = try? WorkspacePersistence.shared.load(SpatialCanvas.self, from: storageFile) {
                self.currentCanvas = loaded
            }
        }
    }
}
