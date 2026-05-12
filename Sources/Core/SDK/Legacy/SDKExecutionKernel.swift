import Foundation

/// Central execution orchestrator for the SDK.
/// Routes all SDK calls into Workspace Core systems.
public final class SDKExecutionKernel {
    public static let shared = SDKExecutionKernel()

    private let router = SDKSystemRouter.shared
    private let dispatcher = SDKActionDispatcher.shared
    private let dependencyResolver = SDKDependencyResolver.shared
    private let synchronizer = SDKStateSynchronizer.shared
    private let telemetry = SDKTelemetryEngine.shared
    private let gate = SDKPermissionGate.shared

    private init() {}

    public func execute(action: SDKAction, context: SDKExecutionContext) async throws {
        let traceID = UUID()
        telemetry.startTrace(id: traceID, action: action)

        do {
            // 1. Resolve dependencies
            try dependencyResolver.validate(action: action)

            // 2. Check permissions
            try await gate.enforce(action: action, context: context)

            // 3. Route to target system
            let systemAction = try router.route(action: action)

            // 4. Dispatch action
            try await dispatcher.dispatch(systemAction, context: context)

            // 5. Synchronize state
            synchronizer.sync(action: action)

            // 6. Broadcast event
            SDKEventInjectionEngine.shared.broadcast(action: action)

            telemetry.endTrace(id: traceID, status: .success)
        } catch {
            telemetry.endTrace(id: traceID, status: .failure(error))
            throw error
        }
    }
}

public enum SDKAction: Sendable {
    case createNote(title: String, content: String)
    case createTask(title: String, dueDate: Date?)
    case sendMail(to: String, subject: String, body: String)
    case createEvent(title: String, start: Date, end: Date)
    case deleteFile(id: String)
    case createDeck(title: String)
    case startMeeting(title: String)
    case restoreSnapshot(id: UUID)
    case queryPersona(prompt: String)
    case injectMemory(entityID: UUID, memory: String)
    case executeWorkflow(id: UUID)
    case generateSlideContent(deckID: UUID, prompt: String)
    case updateGraphLink(source: UUID, target: UUID, relation: String)
}
