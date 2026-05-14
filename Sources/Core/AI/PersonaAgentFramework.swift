import Foundation
import Combine

public enum AgentTaskStatus: String, Codable {
    case idle, planning, executing, completed, failed, rollback
}

public struct AgentActionLog: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let tokenId: String
    public let scopesUsed: UInt64
    public let dependencies: [String]
    public let stateChanges: String
}

public final class PersonaAgentFramework: ObservableObject {
    public static let shared = PersonaAgentFramework()

    @Published public private(set) var currentStatus: AgentTaskStatus = .idle
    @Published public private(set) var executionLogs: [AgentActionLog] = []

    private let authManager = AuthorizationManager.shared

    private init() {}

    // MARK: - Core Engine

    public func processIntent(_ intent: String) async {
        guard let token = authManager.activeToken else {
            logFailure("Execution blocked: No valid token")
            return
        }

        currentStatus = .planning
        let plan = await constructExecutionPlan(for: intent)

        currentStatus = .executing
        await executePlan(plan)
    }

    // MARK: - Execution Intelligence

    private func constructExecutionPlan(for intent: String) async -> [String] {
        // Deterministic intent parsing logic
        return ["resolveDependencies", "invokeLibrary"]
    }

    private func executePlan(_ plan: [String]) async {
        for step in plan {
            do {
                switch step {
                case "resolveDependencies":
                    try resolveDependencies()
                case "invokeLibrary":
                    // Deterministic lookup
                    try await invokeLibrary("com.toolskit.lib.core", capability: "process")
                default:
                    break
                }
            } catch {
                logFailure("Step \(step) failed: \(error.localizedDescription)")
                break
            }
        }
        currentStatus = .completed
    }

    // MARK: - Safety Layer

    public func agentTakeoverWorkspace() async throws {
        guard let currentPayload = authManager.activePayload else { return }
        let escalatedScopes = currentPayload.scp | SDKScope.agentTakeover.rawValue

        // System halts execution for user selection (UI triggered externally)
        _ = authManager.authenticate(userId: currentPayload.uid, scope: SDKScope(rawValue: escalatedScopes))
    }

    // MARK: - Toolchain

    public func installPackage(_ pkgId: String) throws {
        try validateExecution(requiredScope: .sdkManagePackages)
        logAction("Installed package: \(pkgId)", scopes: .sdkManagePackages)
    }

    public func resolveDependencies() throws {
        try validateExecution(requiredScope: .workspaceRead)
        logAction("Resolved dependency graph", scopes: .workspaceRead)
    }

    public func installLibrary(_ libId: String) throws {
        try validateExecution(requiredScope: .sdkManageLibraries)
        logAction("Installed library: \(libId)", scopes: .sdkManageLibraries)
    }

    public func invokeLibrary(_ libId: String, capability: String) async throws {
        try validateExecution(requiredScope: .libraryInvoke)
        logAction("Invoked library \(libId): \(capability)", scopes: .libraryInvoke)
    }

    public func attachFramework(_ frameworkId: String) throws {
        try validateExecution(requiredScope: .sdkManageFrameworks)
        logAction("Attached framework: \(frameworkId)", scopes: .sdkManageFrameworks)
    }

    public func executeFramework(_ frameworkId: String) async throws {
        try validateExecution(requiredScope: .frameworkExecute)
        logAction("Executed framework: \(frameworkId)", scopes: .frameworkExecute)
    }

    // MARK: - Private Utils

    private func validateExecution(requiredScope: SDKScope) throws {
        guard authManager.authState == .authenticated else {
            throw SDKError.authenticationRequired
        }
        guard authManager.validateScope(requiredScope) else {
            throw SDKError.permissionDenied(scope: "agent.\(requiredScope)")
        }
    }

    private func logAction(_ message: String, scopes: SDKScope) {
        let entry = AgentActionLog(
            id: UUID(),
            timestamp: Date(),
            tokenId: authManager.activeToken?.rawValue.prefix(12).description ?? "none",
            scopesUsed: scopes.rawValue,
            dependencies: [],
            stateChanges: message
        )
        executionLogs.append(entry)
    }

    private func logFailure(_ reason: String) {
        currentStatus = .failed
    }
}
