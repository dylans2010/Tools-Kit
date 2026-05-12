import Foundation
import Combine

/// Links Slides to Notebook databases and external APIs for dynamic data-driven content.
final class DataBindingEngine: ObservableObject {
    nonisolated(unsafe) static let shared = DataBindingEngine()

    struct Binding: Codable, Identifiable, Sendable {
        let id: UUID
        let targetNodeID: UUID
        let targetProperty: String
        let dataSourceURL: String // e.g. "notebook://tableID/rowID/columnID" or "https://api..."
    }

    @Published var activeBindings: [Binding] = []
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func refreshBindings() {
        for binding in activeBindings {
            // Fetch and apply data
        }
    }

    func bind(_ nodeID: UUID, property: String, to source: String) {
        let binding = Binding(id: UUID(), targetNodeID: nodeID, targetProperty: property, dataSourceURL: source)
        activeBindings.append(binding)
    }
}
