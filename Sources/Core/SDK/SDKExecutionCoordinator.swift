import Foundation

@MainActor
public final class SDKExecutionCoordinator {
    public static let shared = SDKExecutionCoordinator()

    private let workspaceState = SDKRuntimeWorkspaceState.shared
    private let dependencyPlanner = SDKDependencyExecutionPlanner()
    private let scopeValidator = SDKDependencyScopeValidator()
    private let libraryEngine = SDKLibraryExecutionEngine()

    private init() {}

    public struct ExecutionReport {
        public let startedAt: Date
        public let finishedAt: Date
        public let orderedNodes: [SDKDependencyNode]
        public let executedLibraries: [String]
    }

    public func executeSelectedRunConfiguration() async throws -> ExecutionReport {
        guard let project = SDKProjectManager.shared.currentProject else {
            throw SDKError.executionFailed(reason: "No active SDK project")
        }

        let startedAt = Date()
        let grantedScopes = workspaceState.effectiveScopes(for: project)
        let selectedConfig = workspaceState.selectedRunConfiguration
        let plannedDependencies = workspaceState.dependencies.filter { node in
            guard let config = selectedConfig, !config.scopedExecution.isEmpty else { return true }
            return Set(node.requiredScopes).isSubset(of: grantedScopes) || node.requiredScopes.isEmpty
        }

        try scopeValidator.validate(dependencies: plannedDependencies, grantedScopes: grantedScopes)

        let ordered = try dependencyPlanner.resolveExecutionOrder(for: plannedDependencies)

        let libraryMap = Dictionary(uniqueKeysWithValues: workspaceState.libraries.map { ($0.name, $0) })
        var executedLibraries: [String] = []

        for node in ordered {
            guard node.kind == .library, let library = libraryMap[node.name] else { continue }
            _ = try await libraryEngine.executeLibrary(
                library,
                function: library.exportedFunctions.first?.name,
                projectScopes: grantedScopes
            )
            executedLibraries.append(library.name)
        }

        let report = ExecutionReport(
            startedAt: startedAt,
            finishedAt: Date(),
            orderedNodes: ordered,
            executedLibraries: executedLibraries
        )

        SDKLogStore.shared.log(
            "SDKExecutionCoordinator executed \(executedLibraries.count) libraries in \(ordered.count) dependency nodes",
            source: "SDKExecutionCoordinator",
            level: .info
        )

        return report
    }
}
