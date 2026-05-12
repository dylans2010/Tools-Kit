import Foundation

public struct SDKStructureValidationResult: Sendable {
    public var duplicateModules: [String]
    public var invalidReferences: [String]
    public var circularDependencies: [String]

    public var isValid: Bool {
        duplicateModules.isEmpty && invalidReferences.isEmpty && circularDependencies.isEmpty
    }
}

public final class SDKStructureValidator {
    private let planner = SDKDependencyExecutionPlanner()

    public init() {}

    public func validate(libraries: [SDKLibraryDefinition], dependencies: [SDKDependencyNode]) -> SDKStructureValidationResult {
        let duplicates = Dictionary(grouping: libraries, by: { $0.name.lowercased() })
            .filter { $0.value.count > 1 }
            .map { "Duplicate library module: \($0.key)" }

        let ids = Set(dependencies.map { $0.id })
        let invalidReferences = dependencies.flatMap { node in
            node.linkedTo.filter { !ids.contains($0) }.map { _ in "\(node.name) links to a missing dependency node" }
        }

        var circular: [String] = []
        if (try? planner.resolveExecutionOrder(for: dependencies)) == nil {
            circular = ["Circular dependency chain detected"]
        }

        return SDKStructureValidationResult(
            duplicateModules: duplicates,
            invalidReferences: invalidReferences,
            circularDependencies: circular
        )
    }
}
