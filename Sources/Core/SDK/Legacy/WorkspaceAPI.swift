import Foundation

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
            Task {
                await SDKLogStore.shared.log("Note created via WorkspaceAPI: \(title)", source: "WorkspaceAPI.Notes", level: .info)
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
            Task {
                await SDKLogStore.shared.log("Task created via WorkspaceAPI: \(title)", source: "WorkspaceAPI.Tasks", level: .info)
            }
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
            await SDKLogStore.shared.log("Mail sent via WorkspaceAPI to \(to)", source: "WorkspaceAPI.Mail", level: .info)
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
            Task {
                await SDKLogStore.shared.log("Calendar event created via WorkspaceAPI: \(title)", source: "WorkspaceAPI.Calendar", level: .info)
            }
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
            let path = id
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
                Task {
                    await SDKLogStore.shared.log("File deleted via WorkspaceAPI: \(path)", source: "WorkspaceAPI.Files", level: .info)
                }
            } else {
                Task {
                    await SDKLogStore.shared.log("File not found for deletion: \(path)", source: "WorkspaceAPI.Files", level: .warning)
                }
            }
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
            Task {
                await SDKLogStore.shared.log("Slide deck created via WorkspaceAPI: \(title)", source: "WorkspaceAPI.Slides", level: .info)
            }
        }

        func generateContent(deckID: UUID, prompt: String) async throws {
            guard let deck = SlideDecksManager.shared.decks.first(where: { $0.id == deckID }) else {
                throw SDKError.executionFailed(reason: "Slide deck not found: \(deckID)")
            }
            let response = try await PersonaManager.shared.queryPersona(query: "Generate slide content for '\(deck.title)': \(prompt)")
            await SDKLogStore.shared.log("Slide content generated for \(deck.title): \(response.prefix(50))...", source: "WorkspaceAPI.Slides", level: .info)
        }
    }
    let slides = SlidesAPI()

    // MARK: - Meet
    struct MeetAPI {
        func startMeeting(title: String) async throws -> String {
            let session = try await DailyService.shared.createRoom(for: title)
            if let roomURL = await DailyService.shared.internalRoomURL(for: session) {
                await SDKLogStore.shared.log("Meeting started via WorkspaceAPI: \(title) at \(roomURL)", source: "WorkspaceAPI.Meet", level: .info)
                return roomURL.absoluteString
            }
            await SDKLogStore.shared.log("Meeting started via WorkspaceAPI: \(title) (ID: \(session.meetingId))", source: "WorkspaceAPI.Meet", level: .info)
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
            guard let snapshot = TimeTravelManager.shared.snapshots.first(where: { $0.id == snapshotID }) else {
                throw SDKError.executionFailed(reason: "Snapshot not found: \(snapshotID)")
            }
            TimeTravelManager.shared.restore(snapshot)
            Task {
                await SDKLogStore.shared.log("Snapshot restored via WorkspaceAPI: \(snapshotID)", source: "WorkspaceAPI.TimeTravel", level: .info)
            }
        }

        func createSnapshot(message: String) {
            TimeTravelManager.shared.takeSnapshot(message: message)
            Task {
                await SDKLogStore.shared.log("Snapshot created via WorkspaceAPI: \(message)", source: "WorkspaceAPI.TimeTravel", level: .info)
            }
        }
    }
    let timeTravel = TimeTravelAPI()

    // MARK: - Persona
    struct PersonaAPI {
        func queryPersona(prompt: String) async throws -> String {
            let response = try await PersonaManager.shared.queryPersona(query: prompt)
            await SDKLogStore.shared.log("Persona query via WorkspaceAPI", source: "WorkspaceAPI.Persona", level: .info)
            return response
        }

        @MainActor
        func getInsights() -> [String] {
            let memories = PersonaManager.shared.recentMemories()
            return memories.map { $0.response }
        }

        @MainActor
        func injectMemory(entityID: UUID, content: String) {
            PersonaManager.shared.injectMemory(entityID: entityID, content: content)
            Task {
                await SDKLogStore.shared.log("Persona memory injected for \(entityID)", source: "WorkspaceAPI.Persona", level: .info)
            }
        }
    }
    let persona = PersonaAPI()

    // MARK: - Integrations
    struct IntegrationsAPI {
        func executeWorkflow(workflowID: UUID) async throws {
            if let workflow = UnifiedDataStore.shared.integrationWorkflows.first(where: { $0.id == workflowID }) {
                await IntegrationEngine.shared.processWorkflow(workflow, triggerData: [:])
                await SDKLogStore.shared.log("Workflow executed via WorkspaceAPI: \(workflowID)", source: "WorkspaceAPI.Integrations", level: .info)
            } else {
                throw SDKError.executionFailed(reason: "Workflow not found: \(workflowID)")
            }
        }

        func triggerWorkflow(event: String) {
            SDKEventBridge.shared.emit(type: "workflow.trigger", payload: ["event": event])
            Task {
                await SDKLogStore.shared.log("Workflow triggered for event: \(event)", source: "WorkspaceAPI.Integrations", level: .info)
            }
        }
    }
    let integrations = IntegrationsAPI()

    // MARK: - Intelligence
    struct IntelligenceAPI {
        func getGraph() -> SDKGraph {
            return SDKWorkspaceGraphEngine.shared.fetchGraph()
        }

        func updateLink(source: UUID, target: UUID, relation: String) {
            SDKWorkspaceGraphEngine.shared.updateLink(source: source, target: target, relation: relation)
        }
    }
    let intelligence = IntelligenceAPI()
}
