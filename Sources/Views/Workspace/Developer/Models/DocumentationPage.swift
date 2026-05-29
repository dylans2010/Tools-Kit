import Foundation

public enum DocumentationSectionType: String, Codable, CaseIterable {
    case guide = "Guide"
    case reference = "Reference"
    case tutorial = "Tutorial"
    case changelog = "Changelog"
}

public enum SdkLanguage: String, Codable, CaseIterable {
    case swift = "Swift"
    case javascript = "JavaScript"
    case python = "Python"
    case rust = "Rust"
}

public struct Snippet: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var language: SdkLanguage
    public var body: String

    public init(id: UUID = UUID(), title: String, language: SdkLanguage, body: String) {
        self.id = id
        self.title = title
        self.language = language
        self.body = body
    }
}

public enum ChangelogEntryType: String, Codable, CaseIterable {
    case feature = "Feature"
    case improvement = "Improvement"
    case bugfix = "Bug Fix"
    case deprecation = "Deprecation"
}

public struct ChangelogEntry: Identifiable, Codable, Hashable {
    public var id: UUID
    public var type: ChangelogEntryType
    public var description: String

    public init(id: UUID = UUID(), type: ChangelogEntryType, description: String) {
        self.id = id
        self.type = type
        self.description = description
    }
}

public struct DocumentationTranslation: Codable, Hashable {
    public var localeCode: String
    public var title: String
    public var content: String
    public var isUpToDate: Bool

    public init(localeCode: String, title: String, content: String, isUpToDate: Bool = true) {
        self.localeCode = localeCode
        self.title = title
        self.content = content
        self.isUpToDate = isUpToDate
    }
}

public struct DocumentationPage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var title: String
    public var slug: String
    public var content: String
    public var sectionType: DocumentationSectionType
    public var order: Int
    public var isPublished: Bool
    public var publishedAt: Date?
    public var updatedAt: Date
    public var translations: [DocumentationTranslation]

    public init(
        id: UUID = UUID(),
        appID: UUID,
        title: String,
        slug: String,
        content: String = "",
        sectionType: DocumentationSectionType = .guide,
        order: Int = 0,
        isPublished: Bool = false,
        publishedAt: Date? = nil,
        updatedAt: Date = Date(),
        translations: [DocumentationTranslation] = []
    ) {
        self.id = id
        self.appID = appID
        self.title = title
        self.slug = slug
        self.content = content
        self.sectionType = sectionType
        self.order = order
        self.isPublished = isPublished
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.translations = translations
    }
}
