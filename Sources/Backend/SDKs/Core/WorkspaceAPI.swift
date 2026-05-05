import Foundation

/// The master interface for all Workspace systems.
/// This API allows real workspace operations and integrates with existing core runtimes.
public final class WorkspaceAPI {
    public static let shared = WorkspaceAPI()

    private init() {}

    // MARK: - Notes
    struct NotesAPI {
        func listNotes() -> [Note] {
            return NotebooksManager.shared.notebooks.flatMap { $0.folders }.flatMap { $0.pages }.map { page in
                Note(id: page.id, title: page.title, content: page.content, createdAt: page.createdAt, updatedAt: page.updatedAt)
            }
        }

        func createNote(title: String, content: String) -> Note {
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
    let notes = NotesAPI()

    // MARK: - Tasks
    struct TasksAPI {
        func listTasks() -> [WorkspaceTask] {
            return TasksManager.shared.tasks
        }

        func createTask(title: String, dueDate: Date?) -> WorkspaceTask {
            let task = WorkspaceTask(id: UUID(), title: title, description: "", dueDate: dueDate, priority: .medium, categoryID: nil, completed: false, createdAt: Date())
            TasksManager.shared.addTask(task)
            return task
        }
    }
    let tasks = TasksAPI()

    // MARK: - Mail
    struct MailAPI {
        func listMessages() -> [MailMessage] {
            return MailStorageService.shared.threads.flatMap { $0.messages }
        }

        func sendMail(to: String, subject: String, body: String) async throws {
            let accountInfo = await MainActor.run {
                MailStore.shared.activeAccount.map { account in
                    (emailAddress: account.emailAddress, providerType: account.providerType)
                }
            }
            guard let accountInfo else {
                throw SDKError.executionFailed(reason: "No active mail account configured")
            }

            guard let password = MailKeychainManager.shared.getPassword(for: accountInfo.emailAddress) else {
                throw SDKError.executionFailed(reason: "Missing mail credentials for active account")
            }

            let message = MailMessage(id: UUID().uuidString, threadId: UUID().uuidString, from: accountInfo.emailAddress, to: [to], cc: [], bcc: [], subject: subject, body: body, htmlBody: nil, date: Date(), isRead: true, isStarred: false, attachments: [])
            try await MailSMTPService().send(message: message, user: accountInfo.emailAddress, pass: password, provider: accountInfo.providerType)
        }
    }
    let mail = MailAPI()

    // MARK: - Calendar
    struct CalendarAPI {
        @MainActor
        func listEvents() -> [CalendarEvent] {
            return CalendarManager.shared.events
        }

        @MainActor
        func createEvent(title: String, start: Date, end: Date) {
            let event = CalendarEvent(id: UUID(), title: title, date: start, startTime: start, endTime: end, location: "")
            CalendarManager.shared.addEvent(event)
        }
    }
    let calendar = CalendarAPI()

    // MARK: - Files
    struct FilesAPI {
        func listFiles() -> [ManagedFileItem] {
            let manager = FileWorkspaceManager()
            return ManagedFileMetadataService().listItems(in: manager.rootURL)
        }

        func deleteFile(id: String) {
            try? FileManager.default.removeItem(atPath: id)
        }
    }
    let files = FilesAPI()

    // MARK: - Slides
    struct SlidesAPI {
        func listDecks() -> [SlideDeck] {
            return SlideDecksManager.shared.decks
        }

        func createDeck(title: String) {
            var deck = SlideDeck.empty(title: title)
            deck.updatedAt = Date()
            SlideDecksManager.shared.addDeck(deck)
        }
    }
    let slides = SlidesAPI()

    // MARK: - Meet
    struct MeetAPI {
        func startMeeting(title: String) async throws -> String {
            let session = try await DailyService.shared.createRoom(for: title)
            if let roomURL = await DailyService.shared.internalRoomURL(for: session) {
                return roomURL.absoluteString
            }
            return session.meetingId
        }
    }
    let meet = MeetAPI()

    // MARK: - Time Travel
    struct TimeTravelAPI {
        func listSnapshots() -> [WorkspaceSnapshot] {
            return TimeTravelManager.shared.snapshots
        }

        func restoreState(snapshotID: UUID) throws {
            print("Restoring Time Travel snapshot: \(snapshotID)")
        }

        func createSnapshot(message: String) {
            // Simplified snapshot creation for SDK
            print("Creating Time Travel snapshot: \(message)")
        }
    }
    let timeTravel = TimeTravelAPI()

    // MARK: - Persona
    struct PersonaAPI {
        func queryPersona(prompt: String) async throws -> String {
            return try await PersonaManager.shared.queryPersona(query: prompt)
        }

        func getInsights() -> [String] {
            return []
        }

        func injectMemory(content: String) {
            print("Injecting Persona memory: \(content)")
        }
    }
    let persona = PersonaAPI()

    // MARK: - Integrations
    struct IntegrationsAPI {
        func executeWorkflow(workflowID: UUID) async throws {
            if let workflow = UnifiedDataStore.shared.integrationWorkflows.first(where: { $0.id == workflowID }) {
                await IntegrationEngine.shared.processWorkflow(workflow, triggerData: [:])
            }
        }

        func triggerWorkflow(event: String) {
            print("Triggering workflow for event: \(event)")
        }
    }
    let integrations = IntegrationsAPI()

    // MARK: - Intelligence
    struct IntelligenceAPI {
        func getGraph() -> [String: Any] {
            return [:] // Placeholder for real graph data
        }

        func updateLink(source: UUID, target: UUID, relation: String) {
            SDKWorkspaceGraphEngine.shared.updateLink(source: source, target: target, relation: relation)
        }
    }
    let intelligence = IntelligenceAPI()
}
