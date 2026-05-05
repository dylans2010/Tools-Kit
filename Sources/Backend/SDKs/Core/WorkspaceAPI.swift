import Foundation

/// The master interface for all Workspace systems.
/// This API allows real workspace operations and integrates with existing core runtimes.
public final class WorkspaceAPI {
    public static let shared = WorkspaceAPI()

    private init() {}

    // MARK: - Notes
    public struct NotesAPI {
        @MainActor
        public func listNotes() -> [Note] {
            return NotebooksManager.shared.notebooks.flatMap { $0.folders }.flatMap { $0.pages }.map { page in
                Note(id: page.id.uuidString, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
            }
        }

        @MainActor
        public func createNote(title: String, content: String) -> Note {
            if let firstNotebook = NotebooksManager.shared.notebooks.first,
               let firstFolder = firstNotebook.folders.first {
                NotebooksManager.shared.addPage(to: firstFolder.id, in: firstNotebook.id, title: title, content: content)
                // Retrieve the newly created page
                if let newPage = NotebooksManager.shared.notebooks.first(where: { $0.id == firstNotebook.id })?
                    .folders.first(where: { $0.id == firstFolder.id })?
                    .pages.last {
                    return Note(id: newPage.id.uuidString, title: newPage.title, content: newPage.content, createdAt: newPage.createdAt, updatedAt: newPage.updatedAt)
                }
            }
            return Note(id: UUID().uuidString, title: title, content: content, createdAt: Date(), updatedAt: Date())
        }
    }
    public let notes = NotesAPI()

    // MARK: - Tasks
    public struct TasksAPI {
        @MainActor
        public func listTasks() -> [WorkspaceTask] {
            return TasksManager.shared.tasks
        }

        @MainActor
        public func createTask(title: String, dueDate: Date?) -> WorkspaceTask {
            let task = WorkspaceTask(id: UUID(), title: title, description: "", isCompleted: false, dueDate: dueDate, createdAt: Date(), updatedAt: Date(), categoryID: nil, priority: .medium)
            TasksManager.shared.addTask(task)
            return task
        }
    }
    public let tasks = TasksAPI()

    // MARK: - Mail
    public struct MailAPI {
        @MainActor
        public func listMessages() -> [MailMessage] {
            return MailStorageService.shared.messages
        }

        public func sendMail(to: String, subject: String, body: String) async throws {
            let message = MailMessage(id: UUID().uuidString, threadId: UUID().uuidString, subject: subject, from: "sdk@toolskit.internal", to: [to], cc: [], bcc: [], body: body, htmlBody: nil, date: Date(), isRead: true, isFlagged: false, hasAttachments: false, attachments: [], labels: ["SDK"], folder: "Sent")
            let service = MailSMTPService()
            try await service.send(message: message, user: "sdk@internal.com", pass: "password")
        }
    }
    public let mail = MailAPI()

    // MARK: - Calendar
    public struct CalendarAPI {
        @MainActor
        public func listEvents() -> [CalendarEvent] {
            return CalendarManager.shared.events
        }

        @MainActor
        public func createEvent(title: String, start: Date, end: Date) {
            let event = CalendarEvent(id: UUID(), title: title, startDate: start, endDate: end, isAllDay: false, location: nil, notes: nil, categoryID: nil)
            CalendarManager.shared.addEvent(event)
        }
    }
    public let calendar = CalendarAPI()

    // MARK: - Files
    public struct FilesAPI {
        @MainActor
        public func listFiles() -> [ManagedFileItem] {
            let backend = FileManagementBackend()
            return backend.items
        }

        @MainActor
        public func deleteFile(id: String) {
            let backend = FileManagementBackend()
            if let item = backend.items.first(where: { $0.id == id }) {
                backend.delete(item)
            }
        }
    }
    public let files = FilesAPI()

    // MARK: - Slides
    public struct SlidesAPI {
        @MainActor
        public func listDecks() -> [SlideDeck] {
            return SlideDecksManager.shared.decks
        }

        @MainActor
        public func createDeck(title: String) {
            let deck = SlideDeck(id: UUID(), title: title, author: "SDK", createdAt: Date(), updatedAt: Date(), slides: [])
            SlideDecksManager.shared.addDeck(deck)
        }
    }
    public let slides = SlidesAPI()

    // MARK: - Meet
    public struct MeetAPI {
        public func startMeeting(title: String) async throws -> String {
            let session = try await DailyService.shared.createRoom(for: title)
            return session.meetingId
        }
    }
    public let meet = MeetAPI()

    // MARK: - Time Travel
    public struct TimeTravelAPI {
        @MainActor
        public func listSnapshots() -> [WorkspaceSnapshot] {
            return TimeTravelManager.shared.snapshots
        }

        public func createSnapshot(message: String) throws {
            try TimeTravelFramework.shared.createSnapshot(message: message, entityType: "SDK", entityID: UUID(), data: Data())
        }
    }
    public let timeTravel = TimeTravelAPI()

    // MARK: - Persona
    public struct PersonaAPI {
        @MainActor
        public func queryPersona(prompt: String) async throws -> String {
            return try await PersonaManager.shared.queryPersona(prompt: prompt)
        }

        @MainActor
        public func getInsights() -> [PersonaInsight] {
            return PersonaManager.shared.proactiveInsights
        }
    }
    public let persona = PersonaAPI()

    // MARK: - Integrations
    public struct IntegrationsAPI {
        @MainActor
        public func executeWorkflow(workflowID: UUID) async throws {
            if let workflow = UnifiedDataStore.shared.integrationWorkflows.first(where: { $0.id == workflowID }) {
                try await IntegrationEngine.shared.execute(workflow: workflow)
            }
        }
    }
    public let integrations = IntegrationsAPI()
}
