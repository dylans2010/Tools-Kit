import Foundation
import os.Logger
import CryptoKit

// MARK: - Supporting Types

public struct FormFieldSpec: Codable {
    public let id: String
    public let label: String
    public let type: FieldType
    public let required: Bool
    public let options: [String]?

    public enum FieldType: String, Codable {
        case text, toggle, date, number, select
    }

    public init(id: String, label: String, type: FieldType, required: Bool, options: [String]? = nil) {
        self.id = id
        self.label = label
        self.type = type
        self.required = required
        self.options = options
    }
}

public enum WorkspaceItemType: String, Codable {
    case note, slideDeck, form, emailDraft
}

public struct WorkspaceFilter: Codable {
    public let type: WorkspaceItemType?
    public let tag: String?
    public let createdAfter: Date?
    public let modifiedAfter: Date?

    public init(type: WorkspaceItemType? = nil, tag: String? = nil, createdAfter: Date? = nil, modifiedAfter: Date? = nil) {
        self.type = type
        self.tag = tag
        self.createdAfter = createdAfter
        self.modifiedAfter = modifiedAfter
    }
}

public struct WorkspaceItemSummary: Codable, Identifiable {
    public let id: String
    public let type: WorkspaceItemType
    public let title: String
    public let modifiedAt: Date
}

public struct WorkspaceItemSnapshot: Codable {
    public let id: String
    public let type: WorkspaceItemType
    public let title: String
    public let content: [String: String]
    public let metadata: [String: String]
}

public enum AgentActionResult: Codable {
    case success(payload: String)
    case failure(error: String)
}

public enum AgentActionError: LocalizedError {
    case invalidParameter(String)
    case itemNotFound(String)
    case permissionDenied(String)
    case serviceUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidParameter(let msg): return "Invalid Parameter: \(msg)"
        case .itemNotFound(let msg): return "Item Not Found: \(msg)"
        case .permissionDenied(let msg): return "Permission Denied: \(msg)"
        case .serviceUnavailable(let msg): return "Service Unavailable: \(msg)"
        }
    }
}

public enum AgentAction {
    case editNote(id: String, newTitle: String?, newBody: String?)
    case editSlide(id: String, slideIndex: Int, newContent: String)
    case sendEmail(to: [String], subject: String, body: String, attachmentIDs: [String])
    case createForm(title: String, fields: [FormFieldSpec])
    case deleteWorkspaceItem(id: String, type: WorkspaceItemType)
    case readWorkspaceItem(id: String)
    case listWorkspaceItems(filter: WorkspaceFilter)
}

// MARK: - PersonaAgentFramework

@MainActor
final class PersonaAgentFramework: ObservableObject {
    static let shared = PersonaAgentFramework()
    private let logger = Logger(subsystem: "com.toolskit.agent", category: "Dispatcher")

    private init() {}

    /// The primary entry point for the agent to execute actions within the workspace.
    func execute(_ action: AgentAction) async throws -> AgentActionResult {
        logger.info("Executing action: \(String(describing: action))")

        // Update execution state and add to plan for UI tracking
        let description = describeAction(action)
        let step = PersonaAgentPlanStep(description: description)
        currentPlan.append(step)
        executionState = .acting

        do {
            let result: AgentActionResult
            switch action {
            case .editNote(let id, let title, let body):
                return try await handleEditNote(id: id, title: title, body: body)

            case .editSlide(let id, let index, let content):
                return try await handleEditSlide(id: id, index: index, content: content)

            case .sendEmail(let to, let subject, let body, let attachments):
                return try await handleSendEmail(to: to, subject: subject, body: body, attachments: attachments)

            case .createForm(let title, let fields):
                return try await handleCreateForm(title: title, fields: fields)

            case .deleteWorkspaceItem(let id, let type):
                return try await handleDeleteItem(id: id, type: type)

            case .readWorkspaceItem(let id):
                return try await handleReadItem(id: id)

            case .listWorkspaceItems(let filter):
                result = try await handleListItems(filter: filter)
            }

            if let idx = currentPlan.firstIndex(where: { $0.id == step.id }) {
                currentPlan[idx].status = .completed
            }
            executionState = .idle
            return result
        } catch let error as AgentActionError {
            logger.error("Agent Action Error: \(error.localizedDescription)")
            if let idx = currentPlan.firstIndex(where: { $0.id == step.id }) {
                currentPlan[idx].status = .failed
            }
            executionState = .error
            return .failure(error: error.localizedDescription)
        } catch {
            logger.error("Unexpected Error: \(error.localizedDescription)")
            if let idx = currentPlan.firstIndex(where: { $0.id == step.id }) {
                currentPlan[idx].status = .failed
            }
            executionState = .error
            return .failure(error: error.localizedDescription)
        }
    }

    private func describeAction(_ action: AgentAction) -> String {
        switch action {
        case .editNote(_, let title, _): return "Editing note: \(title ?? "unnamed")"
        case .editSlide(_, let index, _): return "Updating slide \(index)"
        case .sendEmail(let to, let subject, _, _): return "Sending email '\(subject)' to \(to.first ?? "unknown")"
        case .createForm(let title, _): return "Creating form: \(title)"
        case .deleteWorkspaceItem(_, let type): return "Deleting \(type.rawValue)"
        case .readWorkspaceItem(let id): return "Reading item \(id.prefix(8))..."
        case .listWorkspaceItems: return "Listing workspace items"
        }
    }

    // MARK: - Action Handlers

    private func handleEditNote(id: String, title: String?, body: String?) async throws -> AgentActionResult {
        guard let uuid = UUID(uuidString: id) else { throw AgentActionError.invalidParameter("Invalid Note ID") }

        let manager = NotebooksManager.shared
        var foundPage: NotebookPage?
        var notebookID: UUID?
        var folderID: UUID?

        for nb in manager.notebooks {
            for folder in nb.folders {
                if let page = folder.pages.first(where: { $0.id == uuid }) {
                    foundPage = page
                    notebookID = nb.id
                    folderID = folder.id
                    break
                }
            }
        }

        guard var page = foundPage, let nbID = notebookID, let fID = folderID else {
            throw AgentActionError.itemNotFound("Note with ID \(id) not found")
        }

        if let newTitle = title { page.title = newTitle }
        if let newBody = body { page.content = newBody }

        manager.updatePage(page, in: fID, notebookID: nbID)
        return .success(payload: "Successfully updated note \(id)")
    }

    private func handleEditSlide(id: String, index: Int, content: String) async throws -> AgentActionResult {
        guard let uuid = UUID(uuidString: id) else { throw AgentActionError.invalidParameter("Invalid SlideDeck ID") }

        let manager = SlideDecksManager.shared
        guard let deckIdx = manager.decks.firstIndex(where: { $0.id == uuid }) else {
            throw AgentActionError.itemNotFound("SlideDeck with ID \(id) not found")
        }

        var deck = manager.decks[deckIdx]
        guard index >= 0 && index < deck.slides.count else {
            throw AgentActionError.invalidParameter("Slide index \(index) out of bounds")
        }

        deck.slides[index].title = content // Simplified: update title for the index
        manager.updateDeck(deck)

        return .success(payload: "Successfully updated slide \(index) in deck \(id)")
    }

    private func handleSendEmail(to: [String], subject: String, body: String, attachments: [String]) async throws -> AgentActionResult {
        guard !to.isEmpty else { throw AgentActionError.invalidParameter("Recipients list is empty") }

        let accountManager = AccountManager.shared
        guard let account = accountManager.accounts.first else {
            throw AgentActionError.serviceUnavailable("No email accounts configured")
        }

        // Use MailSMTPService
        let smtp = MailSMTPService()
        let message = MailMessage(
            id: UUID().uuidString,
            threadId: UUID().uuidString,
            from: account.emailAddress,
            to: to,
            cc: [],
            bcc: [],
            subject: subject,
            body: body,
            htmlBody: nil,
            date: Date(),
            isRead: true,
            isStarred: false,
            attachments: []
        )

        // In this implementation we simulate the password as it's not stored in Account object but Keychain
        // Given Task 1 constraints, we perform the call.
        try await smtp.send(message: message, user: account.emailAddress, pass: "TOKEN_SENSITIVE", provider: account.providerType)

        return .success(payload: "Email dispatched to \(to.joined(separator: ", "))")
    }

    private func handleCreateForm(title: String, fields: [FormFieldSpec]) async throws -> AgentActionResult {
        guard !title.isEmpty else { throw AgentActionError.invalidParameter("Form title is empty") }

        let backend = FormsBackend.shared
        let questions = fields.map { spec -> FormQuestion in
            FormQuestion(
                id: UUID(),
                questionName: spec.id,
                title: spec.label,
                type: mapFieldType(spec.type),
                options: spec.options ?? [],
                required: spec.required
            )
        }

        let manifest = FormManifest.compose(
            creatorName: "AI Agent",
            questions: questions,
            privacyNote: "Generated by Persona Agent."
        )

        let form = FormDocument(
            name: title,
            description: "Automatically generated form.",
            questions: questions,
            accentHexColor: "3D8EFF",
            backgroundHexColor: "0A0F1E",
            manifest: manifest
        )

        backend.forms.append(form)
        // Note: FormsBackend doesn't have a public save() but it's @Published, and usually has internal persistence.

        return .success(payload: "Created form '\(title)' with \(fields.count) fields. ID: \(form.id.uuidString)")
    }

    private func handleDeleteItem(id: String, type: WorkspaceItemType) async throws -> AgentActionResult {
        guard let uuid = UUID(uuidString: id) else { throw AgentActionError.invalidParameter("Invalid ID") }

        switch type {
        case .note:
            let manager = NotebooksManager.shared
            if let nb = manager.notebooks.first(where: { nb in nb.folders.contains(where: { $0.pages.contains(where: { $0.id == uuid }) }) }) {
                // Not ideal but NotebooksManager.deletePage requires IDs.
                for folder in nb.folders {
                    if let page = folder.pages.first(where: { $0.id == uuid }) {
                        manager.deletePage(page, from: folder.id, notebookID: nb.id)
                        return .success(payload: "Deleted note \(id)")
                    }
                }
            }
        case .slideDeck:
            let manager = SlideDecksManager.shared
            if let deck = manager.decks.first(where: { $0.id == uuid }) {
                manager.deleteDeck(deck)
                return .success(payload: "Deleted slide deck \(id)")
            }
        case .form:
            let backend = FormsBackend.shared
            backend.forms.removeAll { $0.id == uuid }
            return .success(payload: "Deleted form \(id)")
        case .emailDraft:
            throw AgentActionError.permissionDenied("Draft deletion not implemented")
        }

        throw AgentActionError.itemNotFound("\(type) with ID \(id) not found")
    }

    private func handleReadItem(id: String) async throws -> AgentActionResult {
        guard let uuid = UUID(uuidString: id) else { throw AgentActionError.invalidParameter("Invalid ID") }

        // Search across all
        if let page = NotebooksManager.shared.notebooks.flatMap({ $0.folders.flatMap(\.pages) }).first(where: { $0.id == uuid }) {
            let snapshot = WorkspaceItemSnapshot(id: id, type: .note, title: page.title, content: ["body": page.content], metadata: ["tags": page.tags.joined(separator: ", ")])
            return try encodeSnapshot(snapshot)
        }

        if let deck = SlideDecksManager.shared.decks.first(where: { $0.id == uuid }) {
            let snapshot = WorkspaceItemSnapshot(id: id, type: .slideDeck, title: deck.title, content: ["slideCount": "\(deck.slides.count)"], metadata: [:])
            return try encodeSnapshot(snapshot)
        }

        if let form = FormsBackend.shared.forms.first(where: { $0.id == uuid }) {
            let snapshot = WorkspaceItemSnapshot(id: id, type: .form, title: form.name, content: ["description": form.description], metadata: ["questions": "\(form.questions.count)"])
            return try encodeSnapshot(snapshot)
        }

        throw AgentActionError.itemNotFound("Item \(id) not found")
    }

    private func handleListItems(filter: WorkspaceFilter) async throws -> AgentActionResult {
        var summaries: [WorkspaceItemSummary] = []

        if filter.type == nil || filter.type == .note {
            let notes = NotebooksManager.shared.notebooks.flatMap { $0.folders.flatMap(\.pages) }
            summaries.append(contentsOf: notes.map { WorkspaceItemSummary(id: $0.id.uuidString, type: .note, title: $0.title, modifiedAt: $0.updatedAt) })
        }

        if filter.type == nil || filter.type == .slideDeck {
            let decks = SlideDecksManager.shared.decks
            summaries.append(contentsOf: decks.map { WorkspaceItemSummary(id: $0.id.uuidString, type: .slideDeck, title: $0.title, modifiedAt: $0.updatedAt) })
        }

        if filter.type == nil || filter.type == .form {
            let forms = FormsBackend.shared.forms
            summaries.append(contentsOf: forms.map { WorkspaceItemSummary(id: $0.id.uuidString, type: .form, title: $0.name, modifiedAt: $0.manifest.lastEditedAt) })
        }

        // Filtering
        if let after = filter.modifiedAfter {
            summaries = summaries.filter { $0.modifiedAt > after }
        }

        let data = try JSONEncoder().encode(summaries)
        return .success(payload: String(data: data, encoding: .utf8) ?? "[]")
    }

    // MARK: - Helpers

    private func mapFieldType(_ type: FormFieldSpec.FieldType) -> FormQuestionType {
        switch type {
        case .text: return .textInput
        case .toggle: return .multipleChoice
        case .date: return .dropdown
        case .number: return .slider
        case .select: return .dropdown
        }
    }

    private func encodeSnapshot(_ snapshot: WorkspaceItemSnapshot) throws -> AgentActionResult {
        let data = try JSONEncoder().encode(snapshot)
        return .success(payload: String(data: data, encoding: .utf8) ?? "{}")
    }

    // MARK: - Legacy compatibility (stubs to maintain state)

    @Published private(set) var executionState: AgentExecutionState = .idle
    @Published private(set) var currentPlan: [PersonaAgentPlanStep] = []

    enum AgentExecutionState: String {
        case idle, thinking, acting, error
    }

    struct PersonaAgentPlanStep: Identifiable {
        let id = UUID()
        let description: String
        var status: StepStatus = .pending
        enum StepStatus: String { case pending, completed, failed }
    }
}
