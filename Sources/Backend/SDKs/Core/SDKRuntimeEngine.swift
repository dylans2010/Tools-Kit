import Foundation
import Combine

/// The execution heart for SDK projects.
/// Manages project lifecycle, runtime state, and execution modes.
public final class SDKRuntimeEngine: ObservableObject {
    public static let shared = SDKRuntimeEngine()

    @Published public var activeProjects: [SDKProject] = []
    @Published public var isNoSandboxModeEnabled: Bool = false

    private let permissionManager = SDKPermissionManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    public func runProject(_ project: SDKProject) {
        SDKConsoleView.LogBus.shared.log("Starting project: \(project.name)", type: .info)

        let executionContext = SDKExecutionContext(
            projectID: project.id,
            noSandbox: isNoSandboxModeEnabled
        )

        // Execute project logic
        Task {
            do {
                try await performExecution(project: project, context: executionContext)
                SDKConsoleView.LogBus.shared.log("Project \(project.name) executed successfully.", type: .success)
            } catch {
                SDKConsoleView.LogBus.shared.log("Project \(project.name) failed: \(error.localizedDescription)", type: .error)
            }
        }
    }

    private func performExecution(project: SDKProject, context: SDKExecutionContext) async throws {
        // Validate permissions unless noSandbox is enabled
        if !context.noSandbox {
            try permissionManager.validateProjectScopes(project)
        } else {
            SDKConsoleView.LogBus.shared.log("WARNING: Running in noSandbox mode. Restrictions bypassed.", type: .warning)
        }

        // Use SDKExecutionBridge to bridge to real systems
        try await SDKExecutionBridge.shared.execute(sourceCode: project.sourceCode, context: context)
    }

    public func stopProject(id: UUID) {
        activeProjects.removeAll { $0.id == id }
        SDKConsoleView.LogBus.shared.log("Stopped project: \(id)", type: .info)
    }
}

public struct SDKProject: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var sourceCode: String
    public var requiredScopes: [String]
    public var status: ProjectStatus

    public enum ProjectStatus: String, Codable {
        case idle, running, error, deployed
    }
}

public struct SDKExecutionContext {
    public let projectID: UUID
    public let noSandbox: Bool
}
