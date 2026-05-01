import Foundation

/// Represents a link between two workspace objects.
struct ObjectDependency: Identifiable {
    let id = UUID()
    let sourceID: UUID
    let targetID: UUID
    let type: DependencyType

    enum DependencyType: String {
        case reference = "References"
        case embedded = "Embedded In"
        case automation = "Triggers"
    }
}

/// Manages and analyzes object relationships.
final class DependencyInspector: ObservableObject {
    static let shared = DependencyInspector()

    @Published var dependencies: [ObjectDependency] = []

    private init() {}

    /// Scans a space for all object relationships.
    func mapRelationships(in space: CollaborationSpace) -> [ObjectDependency] {
        // Logic to scan notebooks for links to sheets, slides in meetings, etc.
        return []
    }

    /// Checks for objects that are not linked to any other objects.
    func detectOrphans(in space: CollaborationSpace) -> [UUID] {
        return []
    }

    /// Analyzes what will be affected if an object is deleted.
    func performImpactAnalysis(objectID: UUID) -> [UUID] {
        return dependencies.filter { $0.targetID == objectID }.map { $0.sourceID }
    }
}
