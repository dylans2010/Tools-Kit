import Foundation
import Combine

/// The execution heart for SDK projects.
/// Manages project lifecycle, runtime state, and execution modes.
public final class SDKRuntimeEngine: ObservableObject {
    public static let shared = SDKRuntimeEngine()

    @Published public var activeProjects: [SDKProjectLegacy] = []
    @Published public var isNoSandboxModeEnabled: Bool = false

    private let permissionManager = SDKPermissionManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    public func runProject(_ project: SDKProjectLegacy) {
        Task { @MainActor in
            await SDKLogStore.shared.log("Starting project: \(project.name)", source: "SDKRuntimeEngine", level: .info)
        }

        let executionContext = SDKExecutionContext(
            projectID: project.id,
            noSandbox: isNoSandboxModeEnabled
        )

        // Execute project logic
        Task {
            do {
                try await performExecution(project: project, context: executionContext)
                Task { @MainActor in
                    await SDKLogStore.shared.log("Project \(project.name) executed successfully.", source: "SDKRuntimeEngine", level: .info)
                }
            } catch {
                Task { @MainActor in
                    await SDKLogStore.shared.log("Project \(project.name) failed: \(error.localizedDescription)", source: "SDKRuntimeEngine", level: .error)
                }
            }
        }
    }

    private func performExecution(project: SDKProjectLegacy, context: SDKExecutionContext) async throws {
        // Use SDKExecutionKernel for coordinated execution
        if context.noSandbox {
            Task { @MainActor in
                await SDKLogStore.shared.log("WARNING: Running in noSandbox mode. Restrictions bypassed.", source: "SDKRuntimeEngine", level: .warning)
            }
            try await SDKNoSandboxOverrideController.shared.executeUnrestricted(project.sourceCode)
        } else {
            try await SDKSandboxController.shared.execute(project.sourceCode, context: context)
        }
    }

    public func stopProject(id: UUID) {
        activeProjects.removeAll { $0.id == id }
        Task { @MainActor in
            await SDKLogStore.shared.log("Stopped project: \(id)", source: "SDKRuntimeEngine", level: .info)
        }
    }
}

public struct SDKProjectLegacy: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var sourceCode: String
    public var requiredScopes: [String]
    public var status: ProjectStatus

    public enum ProjectStatus: String, Codable, Sendable {
        case idle, running, error, deployed
    }
}

public struct SDKExecutionContext: Sendable {
    public let projectID: UUID
    public let noSandbox: Bool
}
