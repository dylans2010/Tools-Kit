import Foundation
import Combine

final class NotebooksManager: ObservableObject {
    static let shared = NotebooksManager()

    @Published var notebooks: [Notebook] = []
    @Published var integrations: [IntegrationTool] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Notebooks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var notebooksURL: URL { saveDir.appendingPathComponent("notebooks.json") }
    private var integrationsURL: URL { saveDir.appendingPathComponent("integrations.json") }

    private init() { load() }

    // MARK: - Notebooks

    @discardableResult
    func createNotebook(name: String) -> Notebook {
        let nb = Notebook(name: name)
        notebooks.insert(nb, at: 0)
        saveNotebooks()
        return nb
    }

    func updateNotebook(_ notebook: Notebook) {
        if let idx = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            var updated = notebook
            updated.updatedAt = Date()
            notebooks[idx] = updated
            saveNotebooks()
        }
    }

    func deleteNotebook(_ notebook: Notebook) {
        notebooks.removeAll { $0.id == notebook.id }
        saveNotebooks()
    }

    // MARK: - Folders

    func addFolder(to notebookID: UUID, name: String) {
        guard let idx = notebooks.firstIndex(where: { $0.id == notebookID }) else { return }
        let folder = NotebookFolder(name: name)
        notebooks[idx].folders.append(folder)
        notebooks[idx].updatedAt = Date()
        saveNotebooks()
    }

    func deleteFolder(_ folder: NotebookFolder, from notebookID: UUID) {
        guard let idx = notebooks.firstIndex(where: { $0.id == notebookID }) else { return }
        notebooks[idx].folders.removeAll { $0.id == folder.id }
        notebooks[idx].updatedAt = Date()
        saveNotebooks()
    }

    // MARK: - Pages

    func addPage(to folderID: UUID, in notebookID: UUID, title: String) {
        guard let nbIdx = notebooks.firstIndex(where: { $0.id == notebookID }),
              let fIdx = notebooks[nbIdx].folders.firstIndex(where: { $0.id == folderID }) else { return }
        let page = NotebookPage(title: title)
        notebooks[nbIdx].folders[fIdx].pages.append(page)
        notebooks[nbIdx].updatedAt = Date()
        saveNotebooks()
    }

    func updatePage(_ page: NotebookPage, in folderID: UUID, notebookID: UUID) {
        guard let nbIdx = notebooks.firstIndex(where: { $0.id == notebookID }),
              let fIdx = notebooks[nbIdx].folders.firstIndex(where: { $0.id == folderID }),
              let pIdx = notebooks[nbIdx].folders[fIdx].pages.firstIndex(where: { $0.id == page.id }) else { return }
        var updated = page
        updated.updatedAt = Date()
        notebooks[nbIdx].folders[fIdx].pages[pIdx] = updated
        notebooks[nbIdx].updatedAt = Date()
        saveNotebooks()
    }

    func deletePage(_ page: NotebookPage, from folderID: UUID, notebookID: UUID) {
        guard let nbIdx = notebooks.firstIndex(where: { $0.id == notebookID }),
              let fIdx = notebooks[nbIdx].folders.firstIndex(where: { $0.id == folderID }) else { return }
        notebooks[nbIdx].folders[fIdx].pages.removeAll { $0.id == page.id }
        notebooks[nbIdx].updatedAt = Date()
        saveNotebooks()
    }

    // MARK: - Integrations

    func saveIntegration(_ tool: IntegrationTool) {
        if let idx = integrations.firstIndex(where: { $0.id == tool.id }) {
            integrations[idx] = tool
        } else {
            integrations.append(tool)
        }
        saveIntegrations()
    }

    func deleteIntegration(_ tool: IntegrationTool) {
        integrations.removeAll { $0.id == tool.id }
        saveIntegrations()
    }

    // MARK: - Persistence

    private func saveNotebooks() {
        if let data = try? JSONEncoder().encode(notebooks) {
            try? data.write(to: notebooksURL)
        }
    }

    private func saveIntegrations() {
        if let data = try? JSONEncoder().encode(integrations) {
            try? data.write(to: integrationsURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: notebooksURL),
           let decoded = try? JSONDecoder().decode([Notebook].self, from: data) {
            notebooks = decoded
        }
        if let data = try? Data(contentsOf: integrationsURL),
           let decoded = try? JSONDecoder().decode([IntegrationTool].self, from: data) {
            integrations = decoded
        }
    }

    // MARK: - AI Note Intelligence

    struct AINotebookInsights: Codable {
        let summary: String
        let expandedIdeas: [String]
        let tags: [String]
        let relatedNotes: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["summary", "expandedIdeas", "tags", "relatedNotes"],
          "properties": {
            "summary": { "type": "string" },
            "expandedIdeas": { "type": "array", "items": { "type": "string" } },
            "tags": { "type": "array", "items": { "type": "string" } },
            "relatedNotes": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "summary": .string,
            "expandedIdeas": .array(.string),
            "tags": .array(.string),
            "relatedNotes": .array(.string)
        ])
    }

    @MainActor
    func generateNoteInsights(noteContent: String, notebookContext: String) async throws -> AINotebookInsights {
        // Keep notebook AI responses machine-readable and schema-safe.
        let prompt = """
        Analyze this note (natural language, shorthand, or rough notes are allowed), expand ideas, create tags, and link related notes.

        Note content:
        \(noteContent)

        Notebook context:
        \(notebookContext)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a notebook knowledge assistant that understands informal natural language. Return strict JSON only."
        )
        return try aiDecoder.decode(AINotebookInsights.self, from: json, schema: aiSchema)
    }
}
