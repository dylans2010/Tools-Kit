import Foundation

/// The master interface for all Workspace systems.
/// This API allows real workspace operations and integrates with existing core runtimes.
public final class WorkspaceAPI {
    public static let shared = WorkspaceAPI()

    private init() {}

    // MARK: - Notes
    public struct NotesAPI {
        public func listNotes() -> [Note] {
            return NotebooksManager.shared.notebooks.flatMap { $0.folders }.flatMap { $0.pages }.map { page in
                Note(id: page.id.uuidString, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
            }
        }

        public func createNote(title: String, content: String) -> Note {
            let page = NotebookPage(id: UUID(), title: title, content: content, createdAt: Date(), updatedAt: Date())
            if let firstNotebook = NotebooksManager.shared.notebooks.first,
               let firstFolder = firstNotebook.folders.first {
                var folder = firstFolder
                folder.pages.append(page)
                NotebooksManager.shared.updateFolder(folder, in: firstNotebook)
            }
            return Note(id: page.id.uuidString, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
        }
    }
    public let notes = NotesAPI()

    // MARK: - Tasks
    public struct TasksAPI {
        public func listTasks() -> [WorkspaceTask] {
            return TasksManager.shared.tasks
        }

        public func createTask(title: String, dueDate: Date?) -> WorkspaceTask {
            let task = WorkspaceTask(id: UUID(), title: title, description: "", isCompleted: false, dueDate: dueDate, createdAt: Date(), updatedAt: Date(), categoryID: nil, priority: .medium)
            TasksManager.shared.addTask(task)
            return task
        }
    }
    public let tasks = TasksAPI()

    // MARK: - Mail
    public struct MailAPI {
        public func listMessages() -> [MailMessage] {
            return MailStorageService.shared.messages
        }

        public func sendMail(to: String, subject: String, body: String) async throws {
            let message = MailMessage(id: UUID().uuidString, threadId: UUID().uuidString, subject: subject, from: "sdk@toolskit.internal", to: [to], cc: [], bcc: [], body: body, htmlBody: nil, date: Date(), isRead: true, isFlagged: false, hasAttachments: false, attachments: [], labels: ["SDK"], folder: "Sent")
            try await MailSMTPService.shared.send(message: message)
        }
    }
    public let mail = MailAPI()

    // MARK: - Calendar
    public struct CalendarAPI {
        public func listEvents() -> [CalendarEvent] {
            return CalendarManager.shared.events
        }

        public func createEvent(title: String, start: Date, end: Date) {
            let event = CalendarEvent(id: UUID(), title: title, startDate: start, endDate: end, isAllDay: false, location: nil, notes: nil, categoryID: nil)
            CalendarManager.shared.addEvent(event)
        }
    }
    public let calendar = CalendarAPI()

    // MARK: - Files
    public struct FilesAPI {
        public func listFiles() -> [ManagedFile] {
            return FileWorkspaceManager.shared.listFiles()
        }

        public func deleteFile(id: UUID) {
            FileWorkspaceManager.shared.deleteFile(id: id)
        }
    }
    public let files = FilesAPI()

    // MARK: - Slides
    public struct SlidesAPI {
        public func listDecks() -> [SlideDeck] {
            return SlideDecksManager.shared.decks
        }

        public func createDeck(title: String) {
            let deck = SlideDeck(id: UUID(), title: title, author: "SDK", createdAt: Date(), updatedAt: Date(), slides: [])
            SlideDecksManager.shared.addDeck(deck)
        }
    }
    public let slides = SlidesAPI()

    // MARK: - Meet
    public struct MeetAPI {
        public func startMeeting(title: String) async throws -> String {
            return try await DailyService.shared.createRoom(name: title)
        }
    }
    public let meet = MeetAPI()

    // MARK: - Time Travel
    public struct TimeTravelAPI {
        public func listSnapshots() -> [TimeTravelSnapshot] {
            return TimeTravelManager.shared.snapshots
        }

        public func restoreState(snapshotID: UUID) throws {
            try TimeTravelFramework.shared.restoreFromSnapshot(snapshotID: snapshotID)
        }
    }
    public let timeTravel = TimeTravelAPI()

    // MARK: - Persona
    public struct PersonaAPI {
        public func queryPersona(prompt: String) async throws -> String {
            return try await PersonaManager.shared.queryPersona(prompt: prompt)
        }

        public func getInsights() -> [PersonaInsight] {
            return PersonaManager.shared.proactiveInsights
        }
    }
    public let persona = PersonaAPI()

    // MARK: - Integrations
    public struct IntegrationsAPI {
        public func executeWorkflow(workflowID: UUID) async throws {
            if let workflow = UnifiedDataStore.shared.integrationWorkflows.first(where: { $0.id == workflowID }) {
                try await IntegrationEngine.shared.execute(workflow: workflow)
            }
        }
    }
    public let integrations = IntegrationsAPI()
}
