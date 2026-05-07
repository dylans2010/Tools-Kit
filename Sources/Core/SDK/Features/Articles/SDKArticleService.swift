import Foundation
import Combine

/// Protocol for the SDK articles service.
public protocol SDKArticleServiceProtocol {
    func createArticle(title: String, content: String) throws -> SDKArticle
    func listArticles() -> [SDKArticle]
    func getArticle(id: UUID) -> SDKArticle?
}

/// Full SDK Articles module — handles article creation, parsing, content storage, and search.
@MainActor
public final class SDKArticleService: SDKArticleServiceProtocol, ObservableObject {
    public static let shared = SDKArticleService()

    @Published public private(set) var articles: [SDKArticle] = []
    @Published public private(set) var publishedCount: Int = 0

    private let dataStore = SDKDataStore.shared

    private init() {}

    public func initialize() {
        loadFromStore()
        syncFromWorkspace()
        updatePublishedCount()
    }

    // MARK: - Create

    public func createArticle(title: String, content: String, author: String = "", tags: [String] = []) throws -> SDKArticle {
        let article = SDKArticle(title: title, content: content, author: author, tags: tags)
        try dataStore.save(article)
        articles.insert(article, at: 0)

        SDKEventBus.shared.publish(SDKBusEvent(channel: "articles", name: "article.created", data: ["id": article.id.uuidString, "title": title]))
        Task { await SDKLogStore.shared.log("Article created: \(title)", source: "SDKArticleService", level: .info) }
        return article
    }

    // MARK: - Read

    public func listArticles() -> [SDKArticle] {
        return articles
    }

    public func getArticle(id: UUID) -> SDKArticle? {
        return articles.first { $0.id == id }
    }

    public func publishedArticles() -> [SDKArticle] {
        return articles.filter { $0.isPublished }
    }

    // MARK: - Update

    public func updateArticle(id: UUID, title: String? = nil, content: String? = nil, tags: [String]? = nil) throws {
        guard let index = articles.firstIndex(where: { $0.id == id }) else { return }
        if let title = title { articles[index].title = title }
        if let content = content {
            articles[index].content = content
            articles[index].wordCount = content.split(separator: " ").count
        }
        if let tags = tags { articles[index].tags = tags }
        articles[index].updatedAt = Date()
        try dataStore.save(articles[index])
        SDKEventBus.shared.publish(SDKBusEvent(channel: "articles", name: "article.updated", data: ["id": id.uuidString]))
    }

    // MARK: - Publish/Unpublish

    public func publish(id: UUID) throws {
        guard let index = articles.firstIndex(where: { $0.id == id }) else { return }
        articles[index].isPublished = true
        articles[index].updatedAt = Date()
        try dataStore.save(articles[index])
        updatePublishedCount()
        SDKEventBus.shared.publish(SDKBusEvent(channel: "articles", name: "article.published", data: ["id": id.uuidString]))
    }

    public func unpublish(id: UUID) throws {
        guard let index = articles.firstIndex(where: { $0.id == id }) else { return }
        articles[index].isPublished = false
        articles[index].updatedAt = Date()
        try dataStore.save(articles[index])
        updatePublishedCount()
    }

    // MARK: - Delete

    public func deleteArticle(id: UUID) throws {
        try dataStore.delete(SDKArticle.self, id: id)
        articles.removeAll { $0.id == id }
        updatePublishedCount()
        SDKEventBus.shared.publish(SDKBusEvent(channel: "articles", name: "article.deleted", data: ["id": id.uuidString]))
    }

    // MARK: - Search

    public func searchArticles(query: String) -> [SDKArticle] {
        let lowered = query.lowercased()
        return articles.filter {
            $0.title.lowercased().contains(lowered) ||
            $0.content.lowercased().contains(lowered) ||
            $0.author.lowercased().contains(lowered) ||
            $0.tags.contains { $0.lowercased().contains(lowered) }
        }
    }

    // MARK: - Parsing

    public func parseContent(_ rawContent: String) -> ParsedArticleContent {
        let lines = rawContent.components(separatedBy: "\n")
        let title = lines.first ?? "Untitled"
        let body = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = body.split(separator: " ").count
        let headings = lines.filter { $0.hasPrefix("#") }

        return ParsedArticleContent(
            title: title,
            body: body,
            wordCount: wordCount,
            headings: headings,
            estimatedReadTime: max(1, wordCount / 200)
        )
    }

    // MARK: - Private

    private func loadFromStore() {
        articles = dataStore.fetchAll(SDKArticle.self)
    }

    private func syncFromWorkspace() {
        let collections = UnifiedDataStore.shared.articleCollections
        for collection in collections {
            for article in collection.articles {
                let exists = articles.contains { $0.title == article.title }
                if !exists {
                    let sdkArticle = SDKArticle(
                        title: article.title,
                        content: article.content,
                        author: article.source ?? "",
                        tags: article.tags
                    )
                    try? dataStore.save(sdkArticle)
                    articles.append(sdkArticle)
                }
            }
        }
    }

    private func updatePublishedCount() {
        publishedCount = articles.filter { $0.isPublished }.count
    }
}

// MARK: - Parsed Content

public struct ParsedArticleContent {
    public let title: String
    public let body: String
    public let wordCount: Int
    public let headings: [String]
    public let estimatedReadTime: Int
}
