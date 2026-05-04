import Foundation

class NodeGraphEngine: ObservableObject {
    static let shared = NodeGraphEngine()

    @Published var nodes: [SpatialNode] = []

    private init() {}

    func addNode(entity: WorkspaceEntity, position: CGPoint) {
        nodes.append(SpatialNode(id: UUID(), entity: entity, position: position))
    }

    func updateNodePosition(id: UUID, position: CGPoint) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
        }
    }
}

struct SpatialNode: Identifiable {
    let id: UUID
    let entity: WorkspaceEntity
    var position: CGPoint
}
