import Foundation
import CryptoKit
import os

struct FormFieldSpec: Codable, Hashable {
    enum FieldType: String, Codable, Hashable {
        case text
        case toggle
        case date
        case number
        case select
    }

    let id: String
    let label: String
    let type: FieldType
    let required: Bool
    let options: [String]?
}

enum WorkspaceItemType: String, Codable, CaseIterable {
    case note
    case slideDeck
    case form
    case emailDraft
    case whiteboard
    case spreadsheet
    case calendarEvent
    case task
    case automation
    case article
}

struct WorkspaceFilter: Codable, Hashable {
    var type: WorkspaceItemType?
    var tag: String?
    var createdAfter: Date?
    var modifiedAfter: Date?

    init(type: WorkspaceItemType? = nil, tag: String? = nil, createdAfter: Date? = nil, modifiedAfter: Date? = nil) {
        self.type = type
        self.tag = tag
        self.createdAfter = createdAfter
        self.modifiedAfter = modifiedAfter
    }
}

struct WorkspaceItemSummary: Identifiable, Codable, Hashable {
    var id: String
    var type: WorkspaceItemType
    var title: String
    var modifiedAt: Date
}

struct WorkspaceItemSnapshot: Identifiable, Codable, Hashable {
    var id: String
    var type: WorkspaceItemType
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var details: [String: String]
}


struct WhiteboardNode: Codable, Hashable {
    let title: String
    let content: String
}
enum AgentActionResult {
    case success(AgentActionPayload)
    case failure(AgentActionError)
}

enum AgentActionPayload {
    case message(String)
    case itemSnapshot(WorkspaceItemSnapshot)
    case itemSummaries([WorkspaceItemSummary])
}

enum AgentActionError: Error, LocalizedError {
    case invalidParameter(String)
    case itemNotFound(String)
    case permissionDenied(String)
    case serviceUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        case .itemNotFound(let message):
            return "Item not found: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        }
    }
}

enum AgentAction: Equatable {
    case editNote(id: String, newTitle: String?, newBody: String?)
    case editSlide(id: String, slideIndex: Int, newContent: String)
    case sendEmail(to: [String], subject: String, body: String, attachmentIDs: [String])
    case createForm(title: String, fields: [FormFieldSpec])
    case deleteWorkspaceItem(id: String, type: WorkspaceItemType)
    case readWorkspaceItem(id: String)
    case listWorkspaceItems(filter: WorkspaceFilter)
    case createNote(title: String, content: String, notebookName: String?)
    case createSlideDeck(title: String, slideContents: [String])
    case createWhiteboard(title: String, nodes: [WhiteboardNode])
    case createSpreadsheet(name: String, headers: [String], rows: [[String]])
    case createCalendarEvent(title: String, description: String, startDate: Date, endDate: Date, location: String)
    case createTask(title: String, description: String, priority: String, dueDate: Date?)
    case createAutomation(name: String, triggerDescription: String)
    case searchArticles(query: String)
    case replyToEmail(parameters: ReplyEmailParameters)
    case forwardEmail(parameters: ForwardEmailParameters)
    case editEvent(parameters: EditEventParameters)
    case deleteEvent(parameters: DeleteEventParameters)
    case completeTask(id: String)
    case deleteTask(id: String)
}

struct ReplyEmailParameters: Codable, Equatable {
    let originalMessageID: String
    let body: String
}

struct ForwardEmailParameters: Codable, Equatable {
    let originalMessageID: String
    let recipients: [String]
    let body: String?
}

struct EditEventParameters: Codable, Equatable {
    let id: String
    let title: String?
    let startDate: Date?
    let endDate: Date?
    let location: String?
}

struct DeleteEventParameters: Codable, Equatable {
    let id: String
}

actor PersonaAgentFramework {
    static let shared = PersonaAgentFramework()

    private let logger = Logger(subsystem: "com.toolskit.agent", category: "actions")

    func execute(_ action: AgentAction) async throws -> AgentActionResult {
        logger.info("Executing action: \(String(describing: action), privacy: .public)")

        do {
            return try await run(action)
        } catch let error as AgentActionError {
            logger.error("Agent action failed: \(error.localizedDescription, privacy: .public)")
            if case .invalidParameter = error {
                throw error
            }
            return .failure(error)
        } catch {
            let wrapped = AgentActionError.serviceUnavailable(error.localizedDescription)
            logger.error("Agent action unavailable: \(error.localizedDescription, privacy: .public)")
            return .failure(wrapped)
        }
    }

    private func run(_ action: AgentAction) async throws -> AgentActionResult {
        switch action {
        case .editNote(let id, let newTitle, let newBody):
            try validateEditNote(id: id, newTitle: newTitle, newBody: newBody)
            try await ensureScope(.workspaceWrite)
            let snapshot = try await editNote(id: id, newTitle: newTitle, newBody: newBody)
            return .success(.itemSnapshot(snapshot))

        case .editSlide(let id, let slideIndex, let newContent):
            try validateEditSlide(id: id, slideIndex: slideIndex, newContent: newContent)
            try await ensureScope(.workspaceWrite)
            let snapshot = try await editSlide(id: id, slideIndex: slideIndex, newContent: newContent)
            return .success(.itemSnapshot(snapshot))

        case .sendEmail(let to, let subject, let body, let attachmentIDs):
            try validateSendEmail(to: to, subject: subject, body: body)
            try await ensureScope(.workspaceWrite)
            let receipt = try await sendEmail(to: to, subject: subject, body: body, attachmentIDs: attachmentIDs)
            return .success(.message(receipt))

        case .createForm(let title, let fields):
            try validateCreateForm(title: title, fields: fields)
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createForm(title: title, fields: fields)
            return .success(.itemSnapshot(snapshot))

        case .deleteWorkspaceItem(let id, let type):
            try validateDelete(id: id)
            try await ensureScope(.workspaceWrite)
            let message = try await deleteWorkspaceItem(id: id, type: type)
            return .success(.message(message))

        case .readWorkspaceItem(let id):
            try validateRead(id: id)
            try await ensureScope(.workspaceRead)
            let snapshot = try await readWorkspaceItem(id: id)
            return .success(.itemSnapshot(snapshot))

        case .listWorkspaceItems(let filter):
            try await ensureScope(.workspaceRead)
            let summaries = try await listWorkspaceItems(filter: filter)
            return .success(.itemSummaries(summaries))

        case .createNote(let title, let content, let notebookName):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createNote(title: title, content: content, notebookName: notebookName)
            return .success(.itemSnapshot(snapshot))

        case .createSlideDeck(let title, let slideContents):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createSlideDeck(title: title, slideContents: slideContents)
            return .success(.itemSnapshot(snapshot))

        case .createWhiteboard(let title, let nodes):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createWhiteboard(title: title, nodes: nodes)
            return .success(.itemSnapshot(snapshot))

        case .createSpreadsheet(let name, let headers, let rows):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createSpreadsheet(name: name, headers: headers, rows: rows)
            return .success(.itemSnapshot(snapshot))

        case .createCalendarEvent(let title, let description, let startDate, let endDate, let location):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createCalendarEvent(title: title, description: description, startDate: startDate, endDate: endDate, location: location)
            return .success(.itemSnapshot(snapshot))

        case .createTask(let title, let description, let priority, let dueDate):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createTask(title: title, description: description, priority: priority, dueDate: dueDate)
            return .success(.itemSnapshot(snapshot))

        case .createAutomation(let name, let triggerDescription):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await createAutomation(name: name, triggerDescription: triggerDescription)
            return .success(.itemSnapshot(snapshot))

        case .searchArticles(let query):
            try await ensureScope(.workspaceRead)
            let summaries = try await searchArticles(query: query)
            return .success(.itemSummaries(summaries))

        case .replyToEmail(let params):
            try await ensureScope(.workspaceWrite)
            let message = try await replyToEmail(params)
            return .success(.message(message))

        case .forwardEmail(let params):
            try await ensureScope(.workspaceWrite)
            let message = try await forwardEmail(params)
            return .success(.message(message))

        case .editEvent(let params):
            try await ensureScope(.workspaceWrite)
            let snapshot = try await editEvent(params)
            return .success(.itemSnapshot(snapshot))

        case .deleteEvent(let params):
            try await ensureScope(.workspaceWrite)
            let message = try await deleteEvent(params)
            return .success(.message(message))

        case .completeTask(let id):
            try await ensureScope(.workspaceWrite)
            let message = try await completeTask(id: id)
            return .success(.message(message))

        case .deleteTask(let id):
            try await ensureScope(.workspaceWrite)
            let message = try await deleteTask(id: id)
            return .success(.message(message))
        }
    }

    // MARK: - Intent Classification

    enum PersonaIntent: Equatable {
        case sendEmail(parameters: EmailActionParameters)
        case draftEmail(parameters: EmailActionParameters)
        case replyToEmail(parameters: ReplyEmailParameters)
        case forwardEmail(parameters: ForwardEmailParameters)

        case createNote(parameters: NoteActionParameters)
        case editNote(id: String, title: String?, body: String?)
        case deleteNote(id: String)
        case searchNotes(query: String)

        case createEvent(parameters: EventActionParameters)
        case editEvent(parameters: EditEventParameters)
        case deleteEvent(parameters: DeleteEventParameters)

        case createTask(parameters: TaskActionParameters)
        case completeTask(id: String)
        case deleteTask(id: String)

        case compound(steps: [PersonaIntent])
        case clarificationNeeded(reason: String, missingFields: [String])
        case unknown(rawInput: String)
    }

    struct EmailActionParameters: Codable, Equatable {
        var recipients: [String] = []
        var ccRecipients: [String] = []
        var bccRecipients: [String] = []
        var subject: String?
        var body: String?
        var tone: EmailTone = .professional
        var priority: EmailPriority = .normal
        var attachments: [String] = []
        var scheduledSendDate: Date?
        var replyToMessageID: String?
        var generateSubjectIfMissing: Bool = false
        var generateBodyFromIntent: String?
    }

    enum EmailTone: String, Codable, CaseIterable {
        case professional, friendly, formal, assertive, concise, apologetic, urgent
    }

    enum EmailPriority: String, Codable, CaseIterable {
        case low, normal, high, urgent
    }

    struct NoteActionParameters: Codable, Equatable {
        var title: String?
        var body: String
        var tags: [String] = []
        var folder: String?
        var isPinned: Bool = false
        var color: String? // NoteColor enum if exists, using String for now
        var linkedEmailID: String?
        var generateTitleFromBody: Bool = false
    }

    struct EventActionParameters: Codable, Equatable {
        var title: String
        var description: String = ""
        var startDate: Date
        var endDate: Date
        var location: String = ""
    }

    struct TaskActionParameters: Codable, Equatable {
        var title: String
        var description: String = ""
        var priority: String = "medium"
        var dueDate: Date?
    }

    struct PersonaWorkspaceContext {
        var contacts: [PersonaContact]
        var lastAccessedNote: WorkspaceItemSnapshot?
        var activeDraft: WorkspaceItemSnapshot?
        var recentEmails: [WorkspaceItemSnapshot]
    }

    struct PersonaContact: Codable, Equatable {
        let name: String
        let email: String
    }

    final class PersonaIntentEngine {
        private let nlpProcessor = PersonaNLPProcessor()
        private let contextResolver = PersonaContextResolver()
        private let parameterExtractor = PersonaParameterExtractor()

        func classify(input: String, conversationHistory: [PersonaMessage], workspaceContext: PersonaWorkspaceContext) async -> PersonaIntent {
            let candidates = nlpProcessor.score(input: input)
            guard let top = candidates.first, top.score >= 0.6 else {
                return .unknown(rawInput: input)
            }

            switch top.category {
            case .emailSend:
                var params = EmailActionParameters()
                parameterExtractor.extractEmailParams(from: input, params: &params)
                contextResolver.resolveRecipients(params: &params, history: conversationHistory, context: workspaceContext)
                if params.recipients.isEmpty {
                    return .clarificationNeeded(reason: "Who should I send this email to?", missingFields: ["recipients"])
                }
                return .sendEmail(parameters: params)

            case .noteCreate:
                let body = parameterExtractor.extractNoteBody(from: input)
                if body.isEmpty {
                    return .clarificationNeeded(reason: "What should the note say?", missingFields: ["body"])
                }
                return .createNote(parameters: .init(title: nil, body: body))

            case .noteDelete:
                if let id = contextResolver.resolveNoteID(from: input, context: workspaceContext) {
                    return .deleteNote(id: id)
                }
                return .clarificationNeeded(reason: "Which note would you like to delete?", missingFields: ["id"])

            default:
                return .unknown(rawInput: input)
            }
        }
    }

    private enum IntentCategory: String {
        case emailSend = "email_send"
        case emailDraft = "email_draft"
        case noteCreate = "note_create"
        case noteDelete = "note_delete"
        case eventCreate = "event_create"
        case taskCreate = "task_create"
    }

    private struct PersonaNLPProcessor {
        private let keywords: [IntentCategory: [String]] = [
            .emailSend: ["send", "email", "write to", "reach out to", "message", "shoot an email", "drop a line"],
            .emailDraft: ["draft", "compose", "prepare email"],
            .noteCreate: ["create note", "take a note", "write down", "new note", "remember"],
            .noteDelete: ["delete note", "remove note", "discard note"],
            .eventCreate: ["schedule", "meeting", "calendar", "event", "set a meeting"],
            .taskCreate: ["create task", "add task", "remind me to", "new task"]
        ]

        func score(input: String) -> [(category: IntentCategory, score: Double)] {
            let lower = input.lowercased()
            var results: [(IntentCategory, Double)] = []
            for (category, list) in keywords {
                var score = 0.0
                for keyword in list {
                    if let range = lower.range(of: keyword) {
                        let positionWeight = 1.0 - (Double(lower.distance(from: lower.startIndex, to: range.lowerBound)) / Double(lower.count))
                        score += (1.0 + positionWeight)
                    }
                }
                if score > 0 { results.append((category, score)) }
            }
            return results.sorted { $0.1 > $1.1 }
        }
    }

    private struct PersonaContextResolver {
        func resolveRecipients(params: inout EmailActionParameters, history: [PersonaMessage], context: PersonaWorkspaceContext) {
            if params.recipients.isEmpty {
                if let lastPerson = context.contacts.last?.email {
                    params.recipients.append(lastPerson)
                }
            }
        }

        func resolveNoteID(from text: String, context: PersonaWorkspaceContext) -> String? {
            if text.lowercased().contains("that note") || text.lowercased().contains("last note") {
                return context.lastAccessedNote?.id
            }
            return nil
        }
    }

    private struct PersonaParameterExtractor {
        func extractEmailParams(from text: String, params: inout EmailActionParameters) {
            let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            if let regex = try? NSRegularExpression(pattern: emailPattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                params.recipients = matches.map { String(text[Range($0.range, in: text)!]) }
            }

            let lower = text.lowercased()
            if lower.contains("urgent") || lower.contains("asap") { params.priority = .urgent }
            if lower.contains("polite") || lower.contains("friendly") { params.tone = .friendly }
        }

        func extractNoteBody(from text: String) -> String {
            var body = text
            let markers = ["create note", "take a note", "write down", "new note"]
            for marker in markers {
                if let range = body.range(of: marker, options: .caseInsensitive) {
                    body.removeSubrange(text.startIndex..<range.upperBound)
                }
            }
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    final class PersonaActionDispatcher {
        func dispatch(_ intent: PersonaIntent, in context: PersonaWorkspaceContext) async -> PersonaActionResult {
            switch intent {
            case .sendEmail(let params):
                var finalParams = params
                if params.body == nil || params.body?.isEmpty == true {
                    let genBody = try? await AIService.shared.processText(prompt: "Generate an email body for this intent: \(params.subject ?? "send email")", systemPrompt: EmailDraftingTool().systemPrompt)
                    finalParams.body = genBody
                }
                if params.subject == nil || params.subject?.isEmpty == true {
                    let genSub = try? await AIService.shared.processText(prompt: "Generate a subject line for this email body: \(finalParams.body ?? "")", systemPrompt: SubjectLineTool().systemPrompt)
                    finalParams.subject = genSub
                }
                let action = AgentAction.sendEmail(to: finalParams.recipients, subject: finalParams.subject ?? "No Subject", body: finalParams.body ?? "", attachmentIDs: [])
                return .from(try! await PersonaAgentFramework.shared.execute(action))

            case .replyToEmail(let params):
                return .from(try! await PersonaAgentFramework.shared.execute(.replyToEmail(parameters: params)))

            case .forwardEmail(let params):
                return .from(try! await PersonaAgentFramework.shared.execute(.forwardEmail(parameters: params)))

            case .createNote(let params):
                var finalParams = params
                if params.title == nil {
                    let genTitle = try? await AIService.shared.processText(prompt: "Generate a 3-5 word title for this note: \(params.body)", systemPrompt: "You are a title generator. Return only the title text.")
                    finalParams.title = genTitle
                }
                let action = AgentAction.createNote(title: finalParams.title ?? "New Note", content: finalParams.body, notebookName: finalParams.folder)
                return .from(try! await PersonaAgentFramework.shared.execute(action))

            case .editNote(let id, let title, let body):
                return .from(try! await PersonaAgentFramework.shared.execute(.editNote(id: id, newTitle: title, newBody: body)))

            case .deleteNote(let id):
                return .requiresConfirmation(preview: .init(intentDescription: "I'm about to delete a note.", parameterSummary: ["Note ID": id], warningMessage: "This action is permanent and cannot be undone."))

            case .createEvent(let params):
                let action = AgentAction.createCalendarEvent(title: params.title, description: params.description, startDate: params.startDate, endDate: params.endDate, location: params.location)
                return .from(try! await PersonaAgentFramework.shared.execute(action))

            case .editEvent(let params):
                return .from(try! await PersonaAgentFramework.shared.execute(.editEvent(parameters: params)))

            case .deleteEvent(let params):
                return .requiresConfirmation(preview: .init(intentDescription: "I'm about to delete a calendar event.", parameterSummary: ["Event ID": params.id], warningMessage: "This will remove it from your calendar."))

            case .createTask(let params):
                let action = AgentAction.createTask(title: params.title, description: params.description, priority: params.priority, dueDate: params.dueDate)
                return .from(try! await PersonaAgentFramework.shared.execute(action))

            case .completeTask(let id):
                return .from(try! await PersonaAgentFramework.shared.execute(.completeTask(id: id)))

            case .deleteTask(let id):
                return .requiresConfirmation(preview: .init(intentDescription: "I'm about to delete a task.", parameterSummary: ["Task ID": id], warningMessage: "This will permanently remove the task."))

            case .clarificationNeeded(let reason, let fields):
                return .clarificationNeeded(question: reason, missingField: fields.first ?? "")

            case .searchNotes(let query):
                return .from(try! await PersonaAgentFramework.shared.execute(.listWorkspaceItems(filter: .init(type: .note, tag: query))))

            default:
                return .failed(error: .serviceUnavailable("Intent not yet supported in dispatcher."))
            }
        }
    }

    enum PersonaActionResult {
        case success(summary: String, affectedItems: [WorkspaceItemSummary])
        case requiresConfirmation(preview: PersonaActionPreview)
        case failed(error: AgentActionError)
        case clarificationNeeded(question: String, missingField: String)

        // Mapping existing AgentActionResult for internal use
        static func from(_ result: AgentActionResult) -> PersonaActionResult {
            switch result {
            case .success(let payload):
                switch payload {
                case .message(let msg): return .success(summary: msg, affectedItems: [])
                case .itemSnapshot(let snap): return .success(summary: "Action successful", affectedItems: [.init(id: snap.id, type: snap.type, title: snap.title, modifiedAt: snap.modifiedAt)])
                case .itemSummaries(let sums): return .success(summary: "Found items", affectedItems: sums)
                }
            case .failure(let err): return .failed(error: err)
            }
        }
    }

    struct PersonaActionPreview: Equatable {
        let intentDescription: String
        let parameterSummary: [String: String]
        let warningMessage: String?
    }

    // MARK: - Action Implementations

    private func editNote(id: String, newTitle: String?, newBody: String?) async throws -> WorkspaceItemSnapshot {
        guard let noteID = UUID(uuidString: id) else {
            throw AgentActionError.invalidParameter("Note id must be a UUID")
        }

        guard let found = self.findNote(with: noteID) else {
            throw AgentActionError.itemNotFound("No note found with id \(id)")
        }

        return try await MainActor.run {
            var page = found.page
            if let newTitle {
                page.title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let newBody {
                page.content = newBody
            }
            page.updatedAt = Date()

            NotebooksManager.shared.updatePage(page, in: found.folder.id, notebookID: found.notebook.id)

            return WorkspaceItemSnapshot(
                id: page.id.uuidString,
                type: .note,
                title: page.title,
                createdAt: page.createdAt,
                modifiedAt: page.updatedAt,
                tags: page.tags,
                details: ["content": page.content]
            )
        }
    }

    private func editSlide(id: String, slideIndex: Int, newContent: String) async throws -> WorkspaceItemSnapshot {
        guard let deckID = UUID(uuidString: id) else {
            throw AgentActionError.invalidParameter("Slide deck id must be a UUID")
        }

        return try await MainActor.run {
            guard var deck = SlideDecksManager.shared.decks.first(where: { $0.id == deckID }) else {
                throw AgentActionError.itemNotFound("No slide deck found with id \(id)")
            }
            guard slideIndex >= 0 && slideIndex < deck.slides.count else {
                throw AgentActionError.invalidParameter("slideIndex \(slideIndex) is out of range")
            }

            deck.slides[slideIndex].title = newContent
            deck.slides[slideIndex].speakerNotes = newContent
            deck.updatedAt = Date()
            SlideDecksManager.shared.updateDeck(deck)

            return WorkspaceItemSnapshot(
                id: deck.id.uuidString,
                type: .slideDeck,
                title: deck.title,
                createdAt: deck.createdAt,
                modifiedAt: deck.updatedAt,
                tags: deck.slides[slideIndex].metadata["tags"]?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
                details: [
                    "slideIndex": String(slideIndex),
                    "slideContent": newContent,
                    "slideCount": String(deck.slides.count)
                ]
            )
        }
    }

    private func sendEmail(to: [String], subject: String, body: String, attachmentIDs: [String]) async throws -> String {
        for recipient in to {
            try await SDKMailService.shared.send(to: recipient, subject: subject, body: body)
        }

        let joinedRecipients = to.joined(separator: ",")
        _ = try? await ToolsKitSDK.shared.writeData(
            scope: .emails,
            title: subject,
            payload: [
                "to": joinedRecipients,
                "body": body,
                "attachmentIDs": attachmentIDs.joined(separator: ",")
            ]
        )

        return "Email dispatched to \(to.count) recipient(s)."
    }

    private func createForm(title: String, fields: [FormFieldSpec]) async throws -> WorkspaceItemSnapshot {
        try await MainActor.run {
            let questions: [FormQuestion] = fields.map { spec in
                FormQuestion(
                    id: UUID(),
                    questionName: spec.id,
                    title: spec.label,
                    type: self.mapFormType(spec.type),
                    options: spec.options ?? [],
                    required: spec.required
                )
            }

            let form = FormDocument(
                name: title,
                description: "Generated by Persona Agent",
                questions: questions,
                accentHexColor: "3D8EFF",
                backgroundHexColor: "0A0F1E",
                manifest: FormManifest.compose(
                    creatorName: "Persona Agent",
                    questions: questions,
                    privacyNote: "Generated in workspace agent mode.",
                    tags: ["agent"]
                )
            )

            FormsBackend.shared.add(form, isOwned: true)

            return WorkspaceItemSnapshot(
                id: form.id.uuidString,
                type: .form,
                title: form.name,
                createdAt: form.manifest.createdAt,
                modifiedAt: form.manifest.lastEditedAt,
                tags: form.manifest.tags,
                details: [
                    "description": form.description,
                    "fieldCount": String(form.questions.count)
                ]
            )
        }
    }

    private func deleteWorkspaceItem(id: String, type: WorkspaceItemType) async throws -> String {
        switch type {
        case .note:
            guard let noteID = UUID(uuidString: id) else {
                throw AgentActionError.invalidParameter("Note id must be a UUID")
            }
            guard let found = self.findNote(with: noteID) else {
                throw AgentActionError.itemNotFound("No note found with id \(id)")
            }
            return try await MainActor.run {
                NotebooksManager.shared.deletePage(found.page, from: found.folder.id, notebookID: found.notebook.id)
                return "Deleted note \(id)."
            }

        case .slideDeck:
            guard let deckID = UUID(uuidString: id) else {
                throw AgentActionError.invalidParameter("Slide deck id must be a UUID")
            }
            return try await MainActor.run {
                guard let deck = SlideDecksManager.shared.decks.first(where: { $0.id == deckID }) else {
                    throw AgentActionError.itemNotFound("No slide deck found with id \(id)")
                }
                SlideDecksManager.shared.deleteDeck(deck)
                return "Deleted slide deck \(id)."
            }

        case .form:
            guard let formID = UUID(uuidString: id) else {
                throw AgentActionError.invalidParameter("Form id must be a UUID")
            }
            return try await MainActor.run {
                guard let form = FormsBackend.shared.forms.first(where: { $0.id == formID }) else {
                    throw AgentActionError.itemNotFound("No form found with id \(id)")
                }
                FormsBackend.shared.remove(form)
                return "Deleted form \(id)."
            }

        case .emailDraft:
            guard let messageID = UUID(uuidString: id) else {
                throw AgentActionError.invalidParameter("Email draft id must be a UUID")
            }
            return try await MainActor.run {
                guard SDKMailService.shared.getMessage(id: messageID) != nil else {
                    throw AgentActionError.itemNotFound("No email draft found with id \(id)")
                }
                try SDKMailService.shared.deleteMessage(id: messageID)
                return "Deleted email draft \(id)."
            }

        case .whiteboard, .spreadsheet, .calendarEvent, .task, .automation, .article:
            return "Deleted \(type.rawValue) \(id)."
        }
    }

    private func readWorkspaceItem(id: String) async throws -> WorkspaceItemSnapshot {
        if let noteID = UUID(uuidString: id), let note = self.findNote(with: noteID) {
            return WorkspaceItemSnapshot(
                id: note.page.id.uuidString,
                type: .note,
                title: note.page.title,
                createdAt: note.page.createdAt,
                modifiedAt: note.page.updatedAt,
                tags: note.page.tags,
                details: [
                    "content": note.page.content,
                    "notebook": note.notebook.name,
                    "folder": note.folder.name
                ]
            )
        }

        if let deckID = UUID(uuidString: id), let deck = await MainActor.run(body: { SlideDecksManager.shared.decks.first(where: { $0.id == deckID }) }) {
            return WorkspaceItemSnapshot(
                id: deck.id.uuidString,
                type: .slideDeck,
                title: deck.title,
                createdAt: deck.createdAt,
                modifiedAt: deck.updatedAt,
                tags: [],
                details: [
                    "slideCount": String(deck.slides.count),
                    "slides": deck.slides.map(\.title).joined(separator: " | ")
                ]
            )
        }

        if let formID = UUID(uuidString: id), let form = await MainActor.run(body: { FormsBackend.shared.forms.first(where: { $0.id == formID }) }) {
            return WorkspaceItemSnapshot(
                id: form.id.uuidString,
                type: .form,
                title: form.name,
                createdAt: form.manifest.createdAt,
                modifiedAt: form.manifest.lastEditedAt,
                tags: form.manifest.tags,
                details: [
                    "description": form.description,
                    "fields": form.questions.map(\.title).joined(separator: " | ")
                ]
            )
        }

        if let messageID = UUID(uuidString: id), let message = await MainActor.run(body: { SDKMailService.shared.getMessage(id: messageID) }) {
            return WorkspaceItemSnapshot(
                id: message.id.uuidString,
                type: .emailDraft,
                title: message.subject,
                createdAt: message.createdAt,
                modifiedAt: message.updatedAt,
                tags: [],
                details: [
                    "from": message.from,
                    "to": message.to.joined(separator: ","),
                    "body": message.body
                ]
            )
        }

        throw AgentActionError.itemNotFound("No workspace item found with id \(id)")
    }

    private func replyToEmail(_ params: ReplyEmailParameters) async throws -> String {
        guard let messageID = UUID(uuidString: params.originalMessageID) else {
            throw AgentActionError.invalidParameter("originalMessageID must be a UUID")
        }
        return try await MainActor.run {
            guard let original = SDKMailService.shared.getMessage(id: messageID) else {
                throw AgentActionError.itemNotFound("No email found with id \(params.originalMessageID)")
            }
            let recipient = original.from
            let subject = "Re: \(original.subject)"
            let body = params.body
            Task {
                try? await SDKMailService.shared.send(to: recipient, subject: subject, body: body)
            }
            return "Replied to email from \(recipient)"
        }
    }

    private func forwardEmail(_ params: ForwardEmailParameters) async throws -> String {
        guard let messageID = UUID(uuidString: params.originalMessageID) else {
            throw AgentActionError.invalidParameter("originalMessageID must be a UUID")
        }
        return try await MainActor.run {
            guard let original = SDKMailService.shared.getMessage(id: messageID) else {
                throw AgentActionError.itemNotFound("No email found with id \(params.originalMessageID)")
            }
            let recipients = params.recipients
            let subject = "Fwd: \(original.subject)"
            let body = params.body ?? "Forwarded message:\n\n\(original.body)"
            for recipient in recipients {
                Task {
                    try? await SDKMailService.shared.send(to: recipient, subject: subject, body: body)
                }
            }
            return "Forwarded email to \(recipients.count) recipient(s)"
        }
    }

    private func editEvent(_ params: EditEventParameters) async throws -> WorkspaceItemSnapshot {
        guard let eventID = UUID(uuidString: params.id) else {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        return try await MainActor.run {
            guard var event = CalendarManager.shared.events.first(where: { $0.id == eventID }) else {
                throw AgentActionError.itemNotFound("No event found with id \(params.id)")
            }
            if let title = params.title { event.title = title }
            if let start = params.startDate { event.startTime = start; event.date = start }
            if let end = params.endDate { event.endTime = end }
            if let loc = params.location { event.location = loc }
            CalendarManager.shared.updateEvent(event)
            return WorkspaceItemSnapshot(
                id: event.id.uuidString,
                type: .calendarEvent,
                title: event.title,
                createdAt: event.createdAt,
                modifiedAt: Date(),
                tags: [],
                details: [:]
            )
        }
    }

    private func deleteEvent(_ params: DeleteEventParameters) async throws -> String {
        guard let eventID = UUID(uuidString: params.id) else {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        return try await MainActor.run {
            guard let event = CalendarManager.shared.events.first(where: { $0.id == eventID }) else {
                throw AgentActionError.itemNotFound("No event found with id \(params.id)")
            }
            CalendarManager.shared.deleteEvent(event)
            return "Deleted event: \(event.title)"
        }
    }

    private func completeTask(id: String) async throws -> String {
        guard let taskID = UUID(uuidString: id) else {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        return try await MainActor.run {
            guard let task = TasksManager.shared.tasks.first(where: { $0.id == taskID }) else {
                throw AgentActionError.itemNotFound("No task found with id \(id)")
            }
            TasksManager.shared.toggleComplete(task)
            return "Task marked as complete: \(task.title)"
        }
    }

    private func deleteTask(id: String) async throws -> String {
        guard let taskID = UUID(uuidString: id) else {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        return try await MainActor.run {
            guard let task = TasksManager.shared.tasks.first(where: { $0.id == taskID }) else {
                throw AgentActionError.itemNotFound("No task found with id \(id)")
            }
            TasksManager.shared.deleteTask(task)
            return "Deleted task: \(task.title)"
        }
    }

    private func listWorkspaceItems(filter: WorkspaceFilter) async throws -> [WorkspaceItemSummary] {
        let snapshots = try await collectWorkspaceSnapshots()

        let filtered = snapshots.filter { snapshot in
            if let type = filter.type, snapshot.type != type {
                return false
            }
            if let tag = filter.tag?.lowercased(), !tag.isEmpty {
                let matchesTag = snapshot.tags.contains(where: { $0.lowercased() == tag })
                if !matchesTag { return false }
            }
            if let createdAfter = filter.createdAfter, snapshot.createdAt < createdAfter {
                return false
            }
            if let modifiedAfter = filter.modifiedAfter, snapshot.modifiedAt < modifiedAfter {
                return false
            }
            return true
        }

        return filtered
            .sorted(by: { $0.modifiedAt > $1.modifiedAt })
            .map { snapshot in
                WorkspaceItemSummary(id: snapshot.id, type: snapshot.type, title: snapshot.title, modifiedAt: snapshot.modifiedAt)
            }
    }

    // MARK: - New Action Implementations

    private func createNote(title: String, content: String, notebookName: String?) async throws -> WorkspaceItemSnapshot {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Note title cannot be empty")
        }

        return try await MainActor.run {
            let manager = NotebooksManager.shared

            let notebook: Notebook
            if let name = notebookName,
               let existing = manager.notebooks.first(where: { $0.name.lowercased() == name.lowercased() }) {
                notebook = existing
            } else if let first = manager.notebooks.first {
                notebook = first
            } else {
                let nbName = notebookName ?? "Agent Notes"
                notebook = manager.createNotebook(name: nbName)
            }

            let folder: NotebookFolder
            if let firstFolder = notebook.folders.first {
                folder = firstFolder
            } else {
                guard let newFolder = manager.addFolder(to: notebook.id, name: "General") else {
                    throw AgentActionError.serviceUnavailable("Could not create folder in notebook")
                }
                folder = newFolder
            }

            manager.addPage(to: folder.id, in: notebook.id, title: title, content: content)

            guard let nbIdx = manager.notebooks.firstIndex(where: { $0.id == notebook.id }),
                  let fIdx = manager.notebooks[nbIdx].folders.firstIndex(where: { $0.id == folder.id }),
                  let page = manager.notebooks[nbIdx].folders[fIdx].pages.last else {
                throw AgentActionError.serviceUnavailable("Note was created but could not be retrieved")
            }

            return WorkspaceItemSnapshot(
                id: page.id.uuidString,
                type: .note,
                title: page.title,
                createdAt: page.createdAt,
                modifiedAt: page.updatedAt,
                tags: page.tags,
                details: [
                    "content": page.content,
                    "notebook": notebook.name,
                    "folder": folder.name
                ]
            )
        }
    }

    private func createSlideDeck(title: String, slideContents: [String]) async throws -> WorkspaceItemSnapshot {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Slide deck title cannot be empty")
        }

        return try await MainActor.run {
            let manager = SlideDecksManager.shared

            var slides: [Slide] = []
            if slideContents.isEmpty {
                slides = [Slide.blank(title: "Slide 1")]
            } else {
                for (index, content) in slideContents.enumerated() {
                    slides.append(Slide.blank(title: content.isEmpty ? "Slide \(index + 1)" : content))
                }
            }

            let deck = SlideDeck(title: title, slides: slides)
            manager.addDeck(deck)

            return WorkspaceItemSnapshot(
                id: deck.id.uuidString,
                type: .slideDeck,
                title: deck.title,
                createdAt: deck.createdAt,
                modifiedAt: deck.updatedAt,
                tags: [],
                details: [
                    "slideCount": String(deck.slides.count),
                    "slides": deck.slides.map(\.title).joined(separator: " | ")
                ]
            )
        }
    }

    private func createWhiteboard(title: String, nodes: [WhiteboardNode]) async throws -> WorkspaceItemSnapshot {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Whiteboard title cannot be empty")
        }

        return try await MainActor.run {
            let store = WhiteboardStore.shared

            var boardNodes: [WhiteboardNode] = []
            for (index, node) in nodes.enumerated() {
                let xPos = 140.0 + Double(index % 3) * 200.0
                let yPos = 120.0 + Double(index / 3) * 160.0
                boardNodes.append(
                    WhiteboardNode(
                        title: node.title,
                        content: node.content,
                        type: .idea,
                        positionX: xPos,
                        positionY: yPos
                    )
                )
            }

            let board = WhiteboardBoard(title: title, nodes: boardNodes)
            store.boards.insert(board, at: 0)

            return WorkspaceItemSnapshot(
                id: board.id.uuidString,
                type: .whiteboard,
                title: board.title,
                createdAt: board.updatedAt,
                modifiedAt: board.updatedAt,
                tags: [],
                details: [
                    "nodeCount": String(board.nodes.count),
                    "nodes": board.nodes.map(\.title).joined(separator: " | ")
                ]
            )
        }
    }

    private func createSpreadsheet(name: String, headers: [String], rows: [[String]]) async throws -> WorkspaceItemSnapshot {
        let sheetName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sheetName.isEmpty else {
            throw AgentActionError.invalidParameter("Spreadsheet name cannot be empty")
        }

        return try await MainActor.run {
            let manager = SpreadsheetsManager.shared

            let colCount = max(headers.count, rows.first?.count ?? 0, 5)
            let rowCount = max(rows.count + 1, 10)

            var sheet = Spreadsheet.empty(name: sheetName, rows: rowCount, columns: colCount)

            for (col, header) in headers.enumerated() where col < colCount {
                sheet.cells[0][col].value = header
            }

            for (rowIdx, row) in rows.enumerated() {
                let targetRow = rowIdx + 1
                guard targetRow < rowCount else { break }
                for (col, value) in row.enumerated() where col < colCount {
                    sheet.cells[targetRow][col].value = value
                }
            }

            manager.spreadsheets.insert(sheet, at: 0)

            return WorkspaceItemSnapshot(
                id: sheet.id.uuidString,
                type: .spreadsheet,
                title: sheet.name,
                createdAt: sheet.createdAt,
                modifiedAt: sheet.updatedAt,
                tags: [],
                details: [
                    "rows": String(rowCount),
                    "columns": String(colCount),
                    "headers": headers.joined(separator: ", ")
                ]
            )
        }
    }

    private func createCalendarEvent(title: String, description: String, startDate: Date, endDate: Date, location: String) async throws -> WorkspaceItemSnapshot {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Event title cannot be empty")
        }

        return try await MainActor.run {
            let manager = CalendarManager.shared

            let event = CalendarEvent(
                title: title,
                description: description,
                date: startDate,
                startTime: startDate,
                endTime: endDate,
                location: location
            )

            manager.addEvent(event)

            let formatter = ISO8601DateFormatter()
            return WorkspaceItemSnapshot(
                id: event.id.uuidString,
                type: .calendarEvent,
                title: event.title,
                createdAt: event.createdAt,
                modifiedAt: event.createdAt,
                tags: [],
                details: [
                    "description": event.description,
                    "start": formatter.string(from: event.startTime),
                    "end": formatter.string(from: event.endTime),
                    "location": event.location
                ]
            )
        }
    }

    private func createTask(title: String, description: String, priority: String, dueDate: Date?) async throws -> WorkspaceItemSnapshot {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Task title cannot be empty")
        }

        return try await MainActor.run {
            let manager = TasksManager.shared

            let taskPriority: WorkspaceTask.TaskPriority
            switch priority.lowercased() {
            case "low": taskPriority = .low
            case "high": taskPriority = .high
            case "critical": taskPriority = .critical
            default: taskPriority = .medium
            }

            let task = WorkspaceTask(
                title: title,
                description: description,
                dueDate: dueDate,
                priority: taskPriority
            )

            manager.addTask(task)

            var details: [String: String] = [
                "description": task.description,
                "priority": task.priority.rawValue,
                "completed": String(task.completed)
            ]
            if let due = task.dueDate {
                details["dueDate"] = ISO8601DateFormatter().string(from: due)
            }

            return WorkspaceItemSnapshot(
                id: task.id.uuidString,
                type: .task,
                title: task.title,
                createdAt: task.createdAt,
                modifiedAt: task.createdAt,
                tags: [],
                details: details
            )
        }
    }

    private func createAutomation(name: String, triggerDescription: String) async throws -> WorkspaceItemSnapshot {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Automation name cannot be empty")
        }

        let automationID = UUID()
        let now = Date()

        _ = try? await ToolsKitSDK.shared.writeData(
            scope: .automations,
            title: name,
            payload: [
                "trigger": triggerDescription,
                "status": "active",
                "createdBy": "PersonaAgent"
            ]
        )

        return WorkspaceItemSnapshot(
            id: automationID.uuidString,
            type: .automation,
            title: name,
            createdAt: now,
            modifiedAt: now,
            tags: [],
            details: [
                "trigger": triggerDescription,
                "status": "active"
            ]
        )
    }

    private func searchArticles(query: String) async throws -> [WorkspaceItemSummary] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentActionError.invalidParameter("Search query cannot be empty")
        }

        let articles = try await ArticlesManager.shared.search(query: query)

        return articles.map { article in
            WorkspaceItemSummary(
                id: article.id.uuidString,
                type: .article,
                title: article.title,
                modifiedAt: article.savedAt
            )
        }
    }

    // MARK: - Helpers

    private func collectWorkspaceSnapshots() async throws -> [WorkspaceItemSnapshot] {
        try await MainActor.run {
            var snapshots: [WorkspaceItemSnapshot] = []

            for notebook in NotebooksManager.shared.notebooks {
                for folder in notebook.folders {
                    for page in folder.pages {
                        snapshots.append(
                            WorkspaceItemSnapshot(
                                id: page.id.uuidString,
                                type: .note,
                                title: page.title,
                                createdAt: page.createdAt,
                                modifiedAt: page.updatedAt,
                                tags: page.tags,
                                details: ["content": page.content]
                            )
                        )
                    }
                }
            }

            for deck in SlideDecksManager.shared.decks {
                snapshots.append(
                    WorkspaceItemSnapshot(
                        id: deck.id.uuidString,
                        type: .slideDeck,
                        title: deck.title,
                        createdAt: deck.createdAt,
                        modifiedAt: deck.updatedAt,
                        tags: [],
                        details: ["slideCount": String(deck.slides.count)]
                    )
                )
            }

            for form in FormsBackend.shared.forms {
                snapshots.append(
                    WorkspaceItemSnapshot(
                        id: form.id.uuidString,
                        type: .form,
                        title: form.name,
                        createdAt: form.manifest.createdAt,
                        modifiedAt: form.manifest.lastEditedAt,
                        tags: form.manifest.tags,
                        details: ["fieldCount": String(form.questions.count)]
                    )
                )
            }

            for message in SDKMailService.shared.listMessages() {
                snapshots.append(
                    WorkspaceItemSnapshot(
                        id: message.id.uuidString,
                        type: .emailDraft,
                        title: message.subject,
                        createdAt: message.createdAt,
                        modifiedAt: message.updatedAt,
                        tags: [],
                        details: ["to": message.to.joined(separator: ",")]
                    )
                )
            }

            return snapshots
        }
    }

    private func ensureScope(_ scope: SDKScope) async throws {
        let allowed = await MainActor.run {
            ToolsKitSDK.shared.validateScope(scope: scope, operation: scope == .workspaceRead ? .read : .write)
        }
        if !allowed {
            throw AgentActionError.permissionDenied("Missing scope \(scope.rawValue)")
        }
    }

    private func findNote(with id: UUID) -> (notebook: Notebook, folder: NotebookFolder, page: NotebookPage)? {
        for notebook in NotebooksManager.shared.notebooks {
            for folder in notebook.folders {
                if let page = folder.pages.first(where: { $0.id == id }) {
                    return (notebook, folder, page)
                }
            }
        }
        return nil
    }

    nonisolated private func mapFormType(_ type: FormFieldSpec.FieldType) -> FormQuestionType {
        switch type {
        case .text: return .textInput
        case .toggle: return .multipleChoice
        case .date: return .textInput
        case .number: return .slider
        case .select: return .dropdown
        }
    }

    private func validateEditNote(id: String, newTitle: String?, newBody: String?) throws {
        if UUID(uuidString: id) == nil {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        if (newTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) && (newBody == nil) {
            throw AgentActionError.invalidParameter("Either newTitle or newBody is required")
        }
    }

    private func validateEditSlide(id: String, slideIndex: Int, newContent: String) throws {
        if UUID(uuidString: id) == nil {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
        if slideIndex < 0 {
            throw AgentActionError.invalidParameter("slideIndex must be >= 0")
        }
        if newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentActionError.invalidParameter("newContent cannot be empty")
        }
    }

    private func validateSendEmail(to: [String], subject: String, body: String) throws {
        if to.isEmpty {
            throw AgentActionError.invalidParameter("at least one recipient is required")
        }
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentActionError.invalidParameter("subject cannot be empty")
        }
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentActionError.invalidParameter("body cannot be empty")
        }

        for recipient in to {
            if !isLikelyEmail(recipient) {
                throw AgentActionError.invalidParameter("invalid recipient email: \(recipient)")
            }
        }
    }

    private func validateCreateForm(title: String, fields: [FormFieldSpec]) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentActionError.invalidParameter("title cannot be empty")
        }
        if fields.isEmpty {
            throw AgentActionError.invalidParameter("fields cannot be empty")
        }

        let ids = fields.map(\.id)
        if Set(ids).count != ids.count {
            throw AgentActionError.invalidParameter("form field ids must be unique")
        }

        for field in fields {
            if field.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AgentActionError.invalidParameter("field id cannot be empty")
            }
            if field.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AgentActionError.invalidParameter("field label cannot be empty")
            }
            if field.type == .select {
                let options = field.options ?? []
                if options.isEmpty {
                    throw AgentActionError.invalidParameter("select field \(field.id) requires options")
                }
            }
        }
    }

    private func validateDelete(id: String) throws {
        if UUID(uuidString: id) == nil {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
    }

    private func validateRead(id: String) throws {
        if UUID(uuidString: id) == nil {
            throw AgentActionError.invalidParameter("id must be a UUID")
        }
    }

    private func isLikelyEmail(_ value: String) -> Bool {
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return false }
        let digest = SHA256.hash(data: Data(email.utf8))
        return email.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", options: .regularExpression) != nil
    }

    // MARK: - AI Response Action Parser

    nonisolated static func parseAgentActions(from response: String) -> [AgentAction] {
        var actions: [AgentAction] = []
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()

        let pattern = #"\[ACTION:\s*(\w+)\((.*?)\)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return actions
        }

        let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, options: [], range: nsRange)

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let actionRange = Range(match.range(at: 1), in: response),
                  let paramsRange = Range(match.range(at: 2), in: response) else { continue }

            let actionName = String(response[actionRange]).lowercased()
            let paramsStr = String(response[paramsRange])
            let params = parseParams(paramsStr)

            switch actionName {
            case "createnote":
                let title = params["title"] ?? "Untitled Note"
                let content = params["content"] ?? params["body"] ?? ""
                let notebook = params["notebook"]
                actions.append(.createNote(title: title, content: content, notebookName: notebook))

            case "createslides", "createslidedeck":
                let title = params["title"] ?? "Untitled Deck"
                let slidesRaw = params["slides"] ?? params["content"] ?? ""
                let slideContents = slidesRaw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                actions.append(.createSlideDeck(title: title, slideContents: slideContents.isEmpty ? ["Slide 1"] : slideContents))

            case "createwhiteboard":
                let title = params["title"] ?? "Untitled Board"
                let nodesRaw = params["nodes"] ?? params["content"] ?? ""
                let nodeEntries = nodesRaw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let nodes = nodeEntries.map { entry -> (title: String, content: String) in
                    let parts = entry.components(separatedBy: ":")
                    if parts.count >= 2 {
                        return (title: parts[0].trimmingCharacters(in: .whitespaces), content: parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces))
                    }
                    return (title: entry, content: "")
                }
                actions.append(.createWhiteboard(title: title, nodes: nodes))

            case "createspreadsheet":
                let name = params["name"] ?? params["title"] ?? "Untitled Spreadsheet"
                let headersRaw = params["headers"] ?? ""
                let headers = headersRaw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let rowsRaw = params["rows"] ?? ""
                let rows: [[String]] = rowsRaw.components(separatedBy: ";").map { row in
                    row.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                }.filter { !$0.allSatisfy { $0.isEmpty } }
                actions.append(.createSpreadsheet(name: name, headers: headers, rows: rows))

            case "createcalendarevent", "createevent":
                let title = params["title"] ?? "Untitled Event"
                let description = params["description"] ?? ""
                let location = params["location"] ?? ""
                let startDate = parseDate(params["start"] ?? params["startDate"] ?? "", isoFormatter: isoFormatter, fallback: fallbackFormatter) ?? Date().addingTimeInterval(3600)
                let endDate = parseDate(params["end"] ?? params["endDate"] ?? "", isoFormatter: isoFormatter, fallback: fallbackFormatter) ?? startDate.addingTimeInterval(3600)
                actions.append(.createCalendarEvent(title: title, description: description, startDate: startDate, endDate: endDate, location: location))

            case "createtask":
                let title = params["title"] ?? "Untitled Task"
                let description = params["description"] ?? ""
                let priority = params["priority"] ?? "medium"
                let dueDate = parseDate(params["dueDate"] ?? params["due"] ?? "", isoFormatter: isoFormatter, fallback: fallbackFormatter)
                actions.append(.createTask(title: title, description: description, priority: priority, dueDate: dueDate))

            case "sendemail":
                let toRaw = params["to"] ?? ""
                let recipients = toRaw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let subject = params["subject"] ?? "No Subject"
                let body = params["body"] ?? params["content"] ?? ""
                actions.append(.sendEmail(to: recipients, subject: subject, body: body, attachmentIDs: []))

            case "createform":
                let title = params["title"] ?? "Untitled Form"
                let fieldsRaw = params["fields"] ?? ""
                let fieldEntries = fieldsRaw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let fields = fieldEntries.enumerated().map { (index, entry) in
                    FormFieldSpec(id: "field_\(index)", label: entry, type: .text, required: true, options: nil)
                }
                if !fields.isEmpty {
                    actions.append(.createForm(title: title, fields: fields))
                }

            case "createautomation":
                let name = params["name"] ?? params["title"] ?? "Untitled Automation"
                let trigger = params["trigger"] ?? params["description"] ?? ""
                actions.append(.createAutomation(name: name, triggerDescription: trigger))

            case "searcharticles", "findarticles":
                let query = params["query"] ?? params["search"] ?? ""
                if !query.isEmpty {
                    actions.append(.searchArticles(query: query))
                }

            case "editnote":
                let id = params["id"] ?? ""
                let newTitle = params["title"]
                let newBody = params["body"] ?? params["content"]
                if !id.isEmpty {
                    actions.append(.editNote(id: id, newTitle: newTitle, newBody: newBody))
                }

            case "deleteworkspaceitem", "delete":
                let id = params["id"] ?? ""
                let typeStr = params["type"] ?? "note"
                if let type = WorkspaceItemType(rawValue: typeStr), !id.isEmpty {
                    actions.append(.deleteWorkspaceItem(id: id, type: type))
                }

            case "listworkspaceitems", "list":
                let typeStr = params["type"]
                let filter = WorkspaceFilter(type: typeStr.flatMap { WorkspaceItemType(rawValue: $0) })
                actions.append(.listWorkspaceItems(filter: filter))

            case "readworkspaceitem", "read":
                let id = params["id"] ?? ""
                if !id.isEmpty {
                    actions.append(.readWorkspaceItem(id: id))
                }

            default:
                break
            }
        }

        return actions
    }

    private nonisolated static func parseParams(_ raw: String) -> [String: String] {
        var params: [String: String] = [:]
        var current = raw[raw.startIndex...]
        while !current.isEmpty {
            guard let eqIndex = current.firstIndex(of: "=") else { break }
            let key = current[current.startIndex..<eqIndex].trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: ","))
            let afterEq = current[current.index(after: eqIndex)...]

            if afterEq.first == "\"" {
                let valueStart = afterEq.index(after: afterEq.startIndex)
                if let closeQuote = afterEq[valueStart...].firstIndex(of: "\"") {
                    params[key] = String(afterEq[valueStart..<closeQuote])
                    let next = afterEq.index(after: closeQuote)
                    current = afterEq[next...]
                } else {
                    params[key] = String(afterEq[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            } else {
                if let commaIndex = afterEq.firstIndex(of: ",") {
                    params[key] = String(afterEq[afterEq.startIndex..<commaIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    current = afterEq[afterEq.index(after: commaIndex)...]
                } else {
                    params[key] = String(afterEq).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
        return params
    }

    private nonisolated static func parseDate(_ value: String, isoFormatter: ISO8601DateFormatter, fallback: ISO8601DateFormatter) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let date = isoFormatter.date(from: trimmed) { return date }
        if let date = fallback.date(from: trimmed) { return date }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd", "MM/dd/yyyy", "MM/dd/yyyy HH:mm"] {
            df.dateFormat = format
            if let date = df.date(from: trimmed) { return date }
        }
        return nil
    }
}
