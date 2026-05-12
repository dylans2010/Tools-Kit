import Foundation
import Combine

final class ArticlesManager: ObservableObject {
    nonisolated(unsafe) static let shared = ArticlesManager()

    @Published var collections: [ArticleCollection] = []
    @Published var recentArticles: [Article] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Articles", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var collectionsURL: URL {
        saveDir.appendingPathComponent("collections.json")
    }

    private var recentURL: URL {
        saveDir.appendingPathComponent("recent.json")
    }

    private init() {
        load()
    }

    // MARK: - Collections CRUD

    func createCollection(name: String, icon: String = "folder", colorHex: String = "3B82F6") {
        let col = ArticleCollection(name: name, icon: icon, colorHex: colorHex)
        collections.insert(col, at: 0)
        saveCollections()
    }

    func updateCollection(_ collection: ArticleCollection) {
        if let idx = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[idx] = collection
            saveCollections()
        }
    }

    func deleteCollection(_ collection: ArticleCollection) {
        collections.removeAll { $0.id == collection.id }
        saveCollections()
    }

    func saveArticle(_ article: Article, to collectionID: UUID) {
        guard let idx = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        if !collections[idx].articles.contains(where: { $0.id == article.id }) {
            collections[idx].articles.append(article)
        }
        saveCollections()
        addRecent(article)
    }

    func removeArticle(_ article: Article, from collectionID: UUID) {
        guard let idx = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        collections[idx].articles.removeAll { $0.id == article.id }
        saveCollections()
    }

    // MARK: - Recent

    func addRecent(_ article: Article) {
        recentArticles.removeAll { $0.sourceURL == article.sourceURL }
        recentArticles.insert(article, at: 0)
        if recentArticles.count > 20 { recentArticles = Array(recentArticles.prefix(20)) }
        saveRecent()
    }

    // MARK: - Wikipedia Search

    func search(query: String, language: String = "en") async throws -> [Article] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://\(language).wikipedia.org/w/api.php?action=query&list=search&srsearch=\(encoded)&format=json&utf8=1&srlimit=20"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let searchResults = (json?["query"] as? [String: Any])?["search"] as? [[String: Any]] ?? []
        return searchResults.map { result in
            let title = result["title"] as? String ?? ""
            let snippet = (result["snippet"] as? String ?? "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let pageID = result["pageid"] as? Int ?? 0
            let sourceURL = "https://\(language).wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))"
            return Article(title: title, summary: snippet, content: "", language: language, sourceURL: sourceURL, pageID: pageID == 0 ? nil : pageID)
        }
    }

    func fetchArticle(title: String, language: String = "en", pageID: Int? = nil) async throws -> Article {
        let urlString: String
        if let pageID {
            urlString = "https://\(language).wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&exintro=false&pageids=\(pageID)&format=json&utf8=1&pithumbsize=400&redirects=1"
        } else {
            let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
            urlString = "https://\(language).wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&exintro=false&titles=\(encoded)&format=json&utf8=1&pithumbsize=400&redirects=1"
        }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let pages = (json?["query"] as? [String: Any])?["pages"] as? [String: Any] ?? [:]
        guard let page = pages.values.first as? [String: Any] else { throw URLError(.cannotParseResponse) }
        let pageTitle = page["title"] as? String ?? title
        let extract = page["extract"] as? String ?? ""
        let thumbnail = (page["thumbnail"] as? [String: Any])?["source"] as? String
        let sourceURL = "https://\(language).wikipedia.org/wiki/\(pageTitle.replacingOccurrences(of: " ", with: "_"))"
        let content = cleanHTML(extract)
        let summary = String(content.prefix(300))
        return Article(title: pageTitle, summary: summary, content: content, imageURL: thumbnail, language: language, sourceURL: sourceURL, pageID: pageID)
    }

    private func cleanHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Persistence

    private func saveCollections() {
        if let data = try? JSONEncoder().encode(collections) {
            try? data.write(to: collectionsURL)
        }
    }

    private func saveRecent() {
        if let data = try? JSONEncoder().encode(recentArticles) {
            try? data.write(to: recentURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: collectionsURL),
           let decoded = try? JSONDecoder().decode([ArticleCollection].self, from: data) {
            collections = decoded
        }
        if let data = try? Data(contentsOf: recentURL),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            recentArticles = decoded
        }
    }

    // MARK: - AI Article Intelligence

    struct AIArticleInsights: Codable, Sendable {
        let summary: String
        let keyPoints: [String]
        let rewrite: String
        let expandedSections: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["summary", "keyPoints", "rewrite", "expandedSections"],
          "properties": {
            "summary": { "type": "string" },
            "keyPoints": { "type": "array", "items": { "type": "string" } },
            "rewrite": { "type": "string" },
            "expandedSections": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "summary": .string,
            "keyPoints": .array(.string),
            "rewrite": .string,
            "expandedSections": .array(.string)
        ])
    }

    @MainActor
    func generateArticleInsights(articleText: String, instruction: String) async throws -> AIArticleInsights {
        // Keep article workflows strictly JSON-driven for reliable rendering.
        let prompt = """
        Instruction:
        \(instruction)

        Article content:
        \(articleText)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are an editorial assistant that handles natural language requests, even short or informal. Return strict JSON only."
        )
        return try aiDecoder.decode(AIArticleInsights.self, from: json, schema: aiSchema)
    }
}
