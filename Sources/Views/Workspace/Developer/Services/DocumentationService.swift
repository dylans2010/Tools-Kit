import Foundation

public class DocumentationService: ObservableObject {
    public static let shared = DocumentationService()
    private let store = DeveloperPersistentStore.shared

    @Published public var pages: [DocumentationPage] = []

    private init() {
        loadPages()
    }

    public func loadPages() {
        self.pages = store.documentationPages
    }

    public func savePage(_ page: DocumentationPage) async throws {
        var currentPages = store.documentationPages
        var updatedPage = page
        updatedPage.updatedAt = Date()

        if let index = currentPages.firstIndex(where: { $0.id == page.id }) {
            currentPages[index] = updatedPage
        } else {
            currentPages.append(updatedPage)
        }

        store.saveDocumentationPages(currentPages)

        await MainActor.run {
            self.pages = currentPages
        }
    }

    public func createPage(appID: UUID, title: String) async throws -> DocumentationPage {
        let slug = generateSlug(from: title)
        let newPage = DocumentationPage(
            appID: appID,
            title: title,
            slug: slug,
            order: (pages.filter { $0.appID == appID }.map { $0.order }.max() ?? -1) + 1
        )
        try await savePage(newPage)
        return newPage
    }

    public func publishPage(id: UUID) async throws {
        var currentPages = store.documentationPages
        if let index = currentPages.firstIndex(where: { $0.id == id }) {
            currentPages[index].isPublished = true
            currentPages[index].publishedAt = Date()
            currentPages[index].updatedAt = Date()

            store.saveDocumentationPages(currentPages)
            await MainActor.run {
                self.pages = currentPages
            }
        }
    }

    public func unpublishPage(id: UUID) async throws {
        var currentPages = store.documentationPages
        if let index = currentPages.firstIndex(where: { $0.id == id }) {
            currentPages[index].isPublished = false
            currentPages[index].updatedAt = Date()

            store.saveDocumentationPages(currentPages)
            await MainActor.run {
                self.pages = currentPages
            }
        }
    }

    public func deletePage(id: UUID) async throws {
        var currentPages = store.documentationPages
        currentPages.removeAll { $0.id == id }
        store.saveDocumentationPages(currentPages)
        await MainActor.run {
            self.pages = currentPages
        }
    }

    public func reorderPages(appID: UUID, pageIDs: [UUID]) async throws {
        var currentPages = store.documentationPages
        for (index, id) in pageIDs.enumerated() {
            if let idx = currentPages.firstIndex(where: { $0.id == id }) {
                currentPages[idx].order = index
            }
        }
        store.saveDocumentationPages(currentPages)
        await MainActor.run {
            self.pages = currentPages
        }
    }

    private func generateSlug(from title: String) -> String {
        let lowercase = title.lowercased()
        let slug = lowercase.replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return slug.isEmpty ? "untitled" : slug
    }
}
