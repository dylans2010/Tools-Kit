import Foundation

/// Routes SDK actions to their respective Workspace modules.
public final class SDKSystemRouter {
    public static let shared = SDKSystemRouter()

    private init() {}

    public func route(action: SDKAction) throws -> SystemAction {
        switch action {
        case .createNote(let title, let content):
            return .notes(.create(title: title, content: content))
        case .createTask(let title, let dueDate):
            return .tasks(.create(title: title, dueDate: dueDate))
        case .sendMail(let to, let subject, let body):
            return .mail(.send(to: to, subject: subject, body: body))
        case .createEvent(let title, let start, let end):
            return .calendar(.create(title: title, start: start, end: end))
        case .deleteFile(let id):
            return .files(.delete(id: id))
        case .createDeck(let title):
            return .slides(.createDeck(title: title))
        case .startMeeting(let title):
            return .meet(.start(title: title))
        case .restoreSnapshot(let id):
            return .timeTravel(.restore(id: id))
        case .queryPersona(let prompt):
            return .persona(.query(prompt: prompt))
        case .injectMemory(let entityID, let memory):
            return .persona(.injectMemory(id: entityID, content: memory))
        case .executeWorkflow(let id):
            return .automation(.execute(id: id))
        case .generateSlideContent(let deckID, let prompt):
            return .slides(.generateContent(id: deckID, prompt: prompt))
        case .updateGraphLink(let source, let target, let relation):
            return .intelligence(.updateLink(source: source, target: target, relation: relation))
        }
    }
}

public enum SystemAction {
    case notes(NotesAction)
    case tasks(TasksAction)
    case mail(MailAction)
    case calendar(CalendarAction)
    case files(FilesAction)
    case slides(SlidesAction)
    case meet(MeetAction)
    case timeTravel(TimeTravelAction)
    case persona(PersonaAction)
    case automation(AutomationAction)
    case intelligence(IntelligenceAction)

    public enum NotesAction { case create(title: String, content: String) }
    public enum TasksAction { case create(title: String, dueDate: Date?) }
    public enum MailAction { case send(to: String, subject: String, body: String) }
    public enum CalendarAction { case create(title: String, start: Date, end: Date) }
    public enum FilesAction { case delete(id: String) }
    public enum SlidesAction { case createDeck(title: String); case generateContent(id: UUID, prompt: String) }
    public enum MeetAction { case start(title: String) }
    public enum TimeTravelAction { case restore(id: UUID) }
    public enum PersonaAction { case query(prompt: String); case injectMemory(id: UUID, content: String) }
    public enum AutomationAction { case execute(id: UUID) }
    public enum IntelligenceAction { case updateLink(source: UUID, target: UUID, relation: String) }
}
