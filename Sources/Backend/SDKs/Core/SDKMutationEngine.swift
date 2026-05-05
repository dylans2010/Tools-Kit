import Foundation

/// Performs workspace mutations (create/edit/delete).
/// Enforces permission and scope validation before execution.
public final class SDKMutationEngine {
    public static let shared = SDKMutationEngine()

    private let gate = SDKPermissionGate.shared
    private let dispatcher = SDKActionDispatcher.shared

    private init() {}

    public func performMutation(_ action: SDKAction, context: SDKExecutionContext) async throws {
        // Enforce permissions
        try gate.enforce(action: action, context: context)

        // Convert to system action and dispatch
        let systemAction = try SDKSystemRouter.shared.route(action: action)
        try await dispatcher.dispatch(systemAction, context: context)

        SDKConsoleView.LogBus.shared.log("Mutation executed: \(action)", type: .success)
    }
}
