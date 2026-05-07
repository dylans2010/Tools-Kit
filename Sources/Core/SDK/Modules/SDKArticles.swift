import Foundation

/// SDKArticles: Manages curated content and articles within the WorkspaceSDK.
public final class SDKArticles {
    public static let shared = SDKArticles()

    private let dataStore = SDKDataStore.shared
    private let collection = "articles"

    public struct Article: SDKModel {
        public let id: UUID
        public let title: String
        public let content: String
        public let author: String
        public let tags: [String]
        public let createdAt: Date
        public var updatedAt: Date

        public init(id: UUID = UUID(), title: String, content: String, author: String, tags: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.title = title
            self.content = content
            self.author = author
            self.tags = tags
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    private init() {
        registerEndpoints()
    }

    private func registerEndpoints() {
        SDKRouter.shared.register(endpoint: "articles.create") { request in
            guard let title = request.parameters["title"] as? String,
                  let content = request.parameters["content"] as? String,
                  let author = request.parameters["author"] as? String else {
                throw SDKArticleError.invalidParameters
            }
            let tags = request.parameters["tags"] as? [String] ?? []
            return try await self.createArticle(title: title, content: content, author: author, tags: tags)
        }

        SDKRouter.shared.register(endpoint: "articles.list") { _ in
            return try self.listArticles()
        }
    }

    public func createArticle(title: String, content: String, author: String, tags: [String]) async throws -> Article {
        try SDKPermissionManager.shared.enforce(scope: .articlesWrite)

        let article = Article(title: title, content: content, author: author, tags: tags)
        try dataStore.save(article, in: collection)

        SDKEventBus.shared.publish(SDKEvent(type: "article.created", source: "SDKArticles", payload: ["title": title, "author": author]))
        return article
    }

    public func listArticles() throws -> [Article] {
        try SDKPermissionManager.shared.enforce(scope: .articlesRead)
        return try dataStore.fetchAll(in: collection)
    }
}

public enum SDKArticleError: Error {
    case invalidParameters
}
