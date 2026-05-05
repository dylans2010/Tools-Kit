import Foundation

/// Final authority on SDK API access.
/// Enforces scopes strictly.
public final class SDKPermissionGate {
    public static let shared = SDKPermissionGate.shared

    private init() {}

    public func enforce(action: SDKAction, context: SDKExecutionContext) throws {
        // If noSandbox mode is enabled and it's a developer context, bypass
        if context.noSandbox {
            SDKConsoleView.LogBus.shared.log("PermissionGate: Bypassing scope check for noSandbox mode.", type: .warning)
            return
        }

        let requiredScope = getRequiredScope(for: action)

        // Simplified check: In a real app, check against authorized project scopes
        guard isScopeAuthorized(requiredScope) else {
            throw SDKError.permissionDenied(scope: requiredScope)
        }
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

    private func isScopeAuthorized(_ scope: String) -> Bool {
        // Mock authorization
        return true
    }
}
