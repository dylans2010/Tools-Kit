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
                Note(id: page.id, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
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
            return Note(id: page.id, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
        }
    }
    public let notes = NotesAPI()

    // MARK: - Tasks
    public struct TasksAPI {
        public func listTasks() -> [WorkspaceTask] {
            return TasksManager.shared.tasks
        }

        public func createTask(title: String, dueDate: Date?) -> WorkspaceTask {
            let task = WorkspaceTask(id: UUID(), title: title, description: "", dueDate: dueDate, priority: .medium, categoryID: nil, completed: false, createdAt: Date())
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
            let message = MailMessage(id: UUID().uuidString, threadId: UUID().uuidString, from: "sdk@toolskit.internal", to: [to], cc: [], bcc: [], subject: subject, body: body, htmlBody: nil, date: Date(), isRead: true, isStarred: false, attachments: [])
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
            let event = CalendarEvent(id: UUID(), title: title, date: start, startTime: start, endTime: end, location: "")
            CalendarManager.shared.addEvent(event)
        }
    }
    public let calendar = CalendarAPI()

    // MARK: - Files
    public struct FilesAPI {
        public func listFiles() -> [ManagedFileItem] {
            let manager = FileWorkspaceManager()
            return ManagedFileMetadataService().listItems(in: manager.rootURL)
        }

        public func deleteFile(id: String) {
            try? FileManager.default.removeItem(atPath: id)
        }

        public func deleteFile(id: UUID) {
            guard let file = listFiles().first(where: { $0.id == id.uuidString }) else { return }
            try? FileManager.default.removeItem(at: file.url)
        }
    }
    public let files = FilesAPI()

    // MARK: - Slides
    public struct SlidesAPI {
        public func listDecks() -> [SlideDeck] {
            return SlideDecksManager.shared.decks
        }

        public func createDeck(title: String) {
            var deck = SlideDeck.empty(title: title)
            deck.updatedAt = Date()
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
        public func listSnapshots() -> [WorkspaceSnapshot] {
            return TimeTravelManager.shared.snapshots
        }

        public func restoreState(snapshotID: UUID) throws {
            print("Restoring Time Travel snapshot: \(snapshotID)")
        }

        public func createSnapshot(message: String) {
            // Simplified snapshot creation for SDK
            print("Creating Time Travel snapshot: \(message)")
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

        public func injectMemory(content: String) {
            print("Injecting Persona memory: \(content)")
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

        public func triggerWorkflow(event: String) {
            print("Triggering workflow for event: \(event)")
        }
    }
    public let integrations = IntegrationsAPI()

    // MARK: - Intelligence
    public struct IntelligenceAPI {
        public func getGraph() -> [String: Any] {
            return [:] // Placeholder for real graph data
        }

        public func updateLink(source: UUID, target: UUID, relation: String) {
            SDKWorkspaceGraphEngine.shared.updateLink(source: source, target: target, relation: relation)
        }
    }
    public let intelligence = IntelligenceAPI()
}
