import Foundation

@available(iOS 27.0, *)
@MainActor
class SCKWorkspaceGenerator {
    static let shared = SCKWorkspaceGenerator()

    func generateAssets(for session: SCKRecordingSession) async throws {
        // Create a Note for the session summary
        if let summary = session.summary {
            let note = Note(
                title: "Summary: \(session.title)",
                content: summary,
                folder: "Screen Captures",
                tags: session.tags + ["SCK", session.featureType.rawValue]
            )
            NotesBackend().notes.append(note)
            NotesBackend().saveNotes()
        }

        // Create Tasks for action items
        if let actions = session.actionItems {
            for action in actions {
                let task = WorkspaceTask(
                    title: action,
                    description: "Generated from recording: \(session.title)",
                    priority: .medium
                )
                TasksManager.shared.addTask(task)
            }
        }
    }
}
