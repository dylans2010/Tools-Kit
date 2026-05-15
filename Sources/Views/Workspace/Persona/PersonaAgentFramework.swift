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

enum AgentAction {
    case editNote(id: String, newTitle: String?, newBody: String?)
    case editSlide(id: String, slideIndex: Int, newContent: String)
    case sendEmail(to: [String], subject: String, body: String, attachmentIDs: [String])
    case createForm(title: String, fields: [FormFieldSpec])
    case deleteWorkspaceItem(id: String, type: WorkspaceItemType)
    case readWorkspaceItem(id: String)
    case listWorkspaceItems(filter: WorkspaceFilter)
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
            try ensureScope(.workspaceWrite)
            let snapshot = try await editNote(id: id, newTitle: newTitle, newBody: newBody)
            return .success(.itemSnapshot(snapshot))

        case .editSlide(let id, let slideIndex, let newContent):
            try validateEditSlide(id: id, slideIndex: slideIndex, newContent: newContent)
            try ensureScope(.workspaceWrite)
            let snapshot = try await editSlide(id: id, slideIndex: slideIndex, newContent: newContent)
            return .success(.itemSnapshot(snapshot))

        case .sendEmail(let to, let subject, let body, let attachmentIDs):
            try validateSendEmail(to: to, subject: subject, body: body)
            try ensureScope(.workspaceWrite)
            let receipt = try await sendEmail(to: to, subject: subject, body: body, attachmentIDs: attachmentIDs)
            return .success(.message(receipt))

        case .createForm(let title, let fields):
            try validateCreateForm(title: title, fields: fields)
            try ensureScope(.workspaceWrite)
            let snapshot = try await createForm(title: title, fields: fields)
            return .success(.itemSnapshot(snapshot))

        case .deleteWorkspaceItem(let id, let type):
            try validateDelete(id: id)
            try ensureScope(.workspaceWrite)
            let message = try await deleteWorkspaceItem(id: id, type: type)
            return .success(.message(message))

        case .readWorkspaceItem(let id):
            try validateRead(id: id)
            try ensureScope(.workspaceRead)
            let snapshot = try await readWorkspaceItem(id: id)
            return .success(.itemSnapshot(snapshot))

        case .listWorkspaceItems(let filter):
            try ensureScope(.workspaceRead)
            let summaries = try await listWorkspaceItems(filter: filter)
            return .success(.itemSummaries(summaries))
        }
    }

    // MARK: - Action Implementations

    private func editNote(id: String, newTitle: String?, newBody: String?) async throws -> WorkspaceItemSnapshot {
        guard let noteID = UUID(uuidString: id) else {
            throw AgentActionError.invalidParameter("Note id must be a UUID")
        }

        return try await MainActor.run {
            guard let found = self.findNote(with: noteID) else {
                throw AgentActionError.itemNotFound("No note found with id \(id)")
            }

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
            return try await MainActor.run {
                guard let found = self.findNote(with: noteID) else {
                    throw AgentActionError.itemNotFound("No note found with id \(id)")
                }
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
        }
    }

    private func readWorkspaceItem(id: String) async throws -> WorkspaceItemSnapshot {
        if let noteID = UUID(uuidString: id), let note = await MainActor.run(body: { self.findNote(with: noteID) }) {
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

    private func ensureScope(_ scope: SDKScope) throws {
        let allowed = ToolsKitSDK.shared.validateScope(scope: scope, operation: scope == .workspaceRead ? .read : .write)
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

    private func mapFormType(_ type: FormFieldSpec.FieldType) -> FormQuestionType {
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
        if digest.isEmpty { return false }
        return email.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", options: .regularExpression) != nil
    }
}
