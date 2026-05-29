import Foundation

public class DocumentationService: ObservableObject {
    public static let shared = DocumentationService()

    @Published public var pages: [DocumentationPage] = []

    private init() {
        loadPages()
    }

    public func loadPages() {
        // Awaiting backend integration
    }

    public func savePage(_ page: DocumentationPage) async throws {
        var updatedPage = page
        updatedPage.updatedAt = Date()
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages[index] = updatedPage
        } else {
            pages.append(updatedPage)
        }
        // Awaiting backend integration
    }

    public func createPage(appID: UUID, title: String) async throws -> DocumentationPage {
        let slug = generateSlug(from: title)
        let newPage = DocumentationPage(appID: appID, title: title, slug: slug)
        try await savePage(newPage)
        return newPage
    }

    public func publishPage(id: UUID) async throws {
        if let index = pages.firstIndex(where: { $0.id == id }) {
            pages[index].isPublished = true
            pages[index].publishedAt = Date()
        }
        // Awaiting backend integration
    }

    public func unpublishPage(id: UUID) async throws {
        if let index = pages.firstIndex(where: { $0.id == id }) {
            pages[index].isPublished = false
        }
        // Awaiting backend integration
    }

    public func deletePage(id: UUID) async throws {
        pages.removeAll { $0.id == id }
        // Awaiting backend integration
    }

    private func generateSlug(from title: String) -> String {
        let lowercase = title.lowercased()
        let slug = lowercase.replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return slug
    }
}
