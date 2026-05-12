import Foundation

public final class SDKPermissionGate {
    nonisolated(unsafe) public static let shared = SDKPermissionGate()

    private init() {}

    @MainActor
    public func enforce(action: SDKAction, context: SDKExecutionContext) throws {
        if context.noSandbox {
            SDKLogStore.shared.log("PermissionGate: Bypassing scope check for noSandbox mode", source: "SDKPermissionGate", level: LogLevel.warning)
            return
        }

        let requiredScope = getRequiredScope(for: action)

        guard SDKScopeManager.shared.isAuthorized(scope: mapActionToSDKScope(action), operation: .execute) else {
            SDKLogStore.shared.log("PermissionGate: Denied scope \(requiredScope) for action \(action)", source: "SDKPermissionGate", level: LogLevel.error)
            throw SDKError.permissionDenied(scope: requiredScope)
        }

        SDKLogStore.shared.log("PermissionGate: Granted scope \(requiredScope)", source: "SDKPermissionGate", level: LogLevel.debug)
    }

    private func getRequiredScope(for action: SDKAction) -> String {
        switch action {
        case .createNote: return "workspace.notes.write"
        case .createTask: return "workspace.tasks.write"
        case .sendMail: return "workspace.mail.send"
        case .createEvent: return "workspace.calendar.write"
        case .deleteFile: return "workspace.files.delete"
        case .createDeck, .generateSlideContent: return "workspace.slides.write"
        case .startMeeting: return "workspace.meet.start"
        case .restoreSnapshot: return "workspace.timetravel.restore"
        case .queryPersona, .injectMemory: return "workspace.persona.access"
        case .executeWorkflow: return "workspace.automation.execute"
        case .updateGraphLink: return "workspace.intelligence.graph"
        }
    }

    private func mapActionToSDKScope(_ action: SDKAction) -> SDKScope {
        switch action {
        case .createNote: return .notes
        case .createTask: return .tasks
        case .sendMail: return .emails
        case .createEvent: return .calendar
        case .deleteFile: return .files
        case .createDeck, .generateSlideContent: return .slides
        case .startMeeting: return .meet
        case .restoreSnapshot: return .all
        case .queryPersona, .injectMemory: return .persona
        case .executeWorkflow: return .automations
        case .updateGraphLink: return .intelligence
        }
    }
}
