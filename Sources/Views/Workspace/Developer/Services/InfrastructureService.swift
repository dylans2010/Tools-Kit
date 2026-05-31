import Foundation

public class InfrastructureService: ObservableObject {
    public static let shared = InfrastructureService()
    private let store = DeveloperPersistentStore.shared

    @Published public var nodes: [InfrastructureNode] = []

    private init() { loadNodes() }

    public func loadNodes() { self.nodes = store.infrastructureNodes }

    public func restartNode(id: UUID) async throws {
        guard var node = store.infrastructureNodes.first(where: { $0.id == id }) else { return }
        node.status = .healthy
        try await updateNode(node)
    }

    public func updateNode(_ node: InfrastructureNode) async throws {
        var current = store.infrastructureNodes
        if let index = current.firstIndex(where: { $0.id == node.id }) {
            current[index] = node
        } else {
            current.append(node)
        }
        store.saveInfrastructureNodes(current)
        await MainActor.run { self.nodes = current }
    }
}
