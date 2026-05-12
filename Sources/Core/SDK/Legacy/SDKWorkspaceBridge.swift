import Foundation

/// Direct interface to Workspace systems.
/// Bypasses abstraction layers when allowed (e.g. noSandbox mode).
public final class SDKWorkspaceBridge {
    nonisolated(unsafe) public static let shared = SDKWorkspaceBridge()

    private let api = WorkspaceAPI.shared

    private init() {}

    // MARK: - Direct Access Methods

    public func performDirectMutation(_ mutation: () -> Void) {
        // Direct mutation logic for high-power execution
        mutation()
    }

    @MainActor
    public func getLiveSystemState() -> [String: Any] {
        return [
            "notes_count": api.notes.listNotes().count,
            "tasks_count": api.tasks.listTasks().count,
            "mail_count": api.mail.listMessages().count,
            "events_count": api.calendar.listEvents().count,
            "files_count": api.files.listFiles().count,
            "decks_count": api.slides.listDecks().count,
            "snapshots_count": api.timeTravel.listSnapshots().count
        ]
    }
}
