import Foundation

class EntityMappingService {
    static let shared = EntityMappingService()

    private init() {}

    func convertMindMapToTasks(_ node: SpatialNode) {
        // Logic to convert visual mind map nodes into actionable tasks
        print("Converting node \(node.entity.title) to task")
    }
}
