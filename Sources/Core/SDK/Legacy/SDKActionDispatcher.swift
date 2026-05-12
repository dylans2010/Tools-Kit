import Foundation

public final class SDKActionDispatcher {
    nonisolated(unsafe) public static let shared = SDKActionDispatcher()

    private let api = WorkspaceAPI.shared

    private init() {}

    public func dispatch(_ action: SystemAction, context: SDKExecutionContext) async throws {
        switch action {
        case .notes(let notesAction):
            switch notesAction {
            case .create(let title, let content):
                _ = api.notes.createNote(title: title, content: content)
                await SDKLogStore.shared.log("Note created: \(title)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .tasks(let tasksAction):
            switch tasksAction {
            case .create(let title, let dueDate):
                _ = api.tasks.createTask(title: title, dueDate: dueDate)
                await SDKLogStore.shared.log("Task created: \(title)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .mail(let mailAction):
            switch mailAction {
            case .send(let to, let subject, let body):
                try await api.mail.sendMail(to: to, subject: subject, body: body)
                await SDKLogStore.shared.log("Mail sent to \(to): \(subject)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .calendar(let calendarAction):
            switch calendarAction {
            case .create(let title, let start, let end):
                await api.calendar.createEvent(title: title, start: start, end: end)
                await SDKLogStore.shared.log("Calendar event created: \(title)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .files(let filesAction):
            switch filesAction {
            case .delete(let id):
                api.files.deleteFile(id: id)
                await SDKLogStore.shared.log("File deleted: \(id)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .slides(let slidesAction):
            switch slidesAction {
            case .createDeck(let title):
                api.slides.createDeck(title: title)
                await SDKLogStore.shared.log("Slide deck created: \(title)", source: "SDKActionDispatcher", level: LogLevel.info)
            case .generateContent(let id, let prompt):
                try await api.slides.generateContent(deckID: id, prompt: prompt)
                await SDKLogStore.shared.log("Slide content generated for deck \(id)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .meet(let meetAction):
            switch meetAction {
            case .start(let title):
                let meetingID = try await api.meet.startMeeting(title: title)
                await SDKLogStore.shared.log("Meeting started: \(title) (\(meetingID))", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .timeTravel(let timeTravelAction):
            switch timeTravelAction {
            case .restore(let id):
                try api.timeTravel.restoreState(snapshotID: id)
                await SDKLogStore.shared.log("Snapshot restored: \(id)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .persona(let personaAction):
            switch personaAction {
            case .query(let prompt):
                let response = try await api.persona.queryPersona(prompt: prompt)
                await SDKLogStore.shared.log("Persona query completed: \(response.prefix(50))...", source: "SDKActionDispatcher", level: LogLevel.info)
            case .injectMemory(let id, let content):
                await api.persona.injectMemory(entityID: id, content: content)
                await SDKLogStore.shared.log("Persona memory injected for entity \(id)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .automation(let automationAction):
            switch automationAction {
            case .execute(let id):
                try await api.integrations.executeWorkflow(workflowID: id)
                await SDKLogStore.shared.log("Workflow executed: \(id)", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        case .intelligence(let intelligenceAction):
            switch intelligenceAction {
            case .updateLink(let source, let target, let relation):
                api.intelligence.updateLink(source: source, target: target, relation: relation)
                await SDKLogStore.shared.log("Graph link updated: \(source) -> \(target) [\(relation)]", source: "SDKActionDispatcher", level: LogLevel.info)
            }
        }
    }
}
