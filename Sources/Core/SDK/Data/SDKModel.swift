import Foundation

/// Base protocol for all SDK-persistable models.
/// Every model stored through the SDK data layer must conform to this.
public protocol SDKModel: Identifiable, Codable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var modelVersion: Int { get }
}

extension SDKModel {
    public var modelVersion: Int { 1 }
}

// MARK: - Feature-Specific Models

/// Mail message model for SDK persistence.
public struct SDKMailMessage: SDKModel {
    public let id: UUID
    public var from: String
    public var to: [String]
    public var cc: [String]
    public var bcc: [String]
    public var subject: String
    public var body: String
    public var htmlBody: String?
    public var isRead: Bool
    public var isStarred: Bool
    public var threadId: String
    public var labels: [String]
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(), from: String, to: [String], cc: [String] = [], bcc: [String] = [],
        subject: String, body: String, htmlBody: String? = nil, isRead: Bool = false,
        isStarred: Bool = false, threadId: String = UUID().uuidString, labels: [String] = []
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.htmlBody = htmlBody
        self.isRead = isRead
        self.isStarred = isStarred
        self.threadId = threadId
        self.labels = labels
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Notebook model for SDK persistence.
public struct SDKNotebook: SDKModel {
    public let id: UUID
    public var title: String
    public var pages: [SDKNotebookPage]
    public var tags: [String]
    public var isPinned: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, pages: [SDKNotebookPage] = [], tags: [String] = [], isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.pages = pages
        self.tags = tags
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Notebook page model.
public struct SDKNotebookPage: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var content: String
    public var versionHistory: [SDKPageVersion]
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, content: String = "") {
        self.id = id
        self.title = title
        self.content = content
        self.versionHistory = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Page version for version history tracking.
public struct SDKPageVersion: Codable, Identifiable {
    public let id: UUID
    public let content: String
    public let savedAt: Date
    public let versionNumber: Int

    public init(content: String, versionNumber: Int) {
        self.id = UUID()
        self.content = content
        self.savedAt = Date()
        self.versionNumber = versionNumber
    }
}

/// Meet session model for SDK persistence.
public struct SDKMeetSession: SDKModel {
    public let id: UUID
    public var title: String
    public var participants: [String]
    public var status: SessionStatus
    public var startedAt: Date?
    public var endedAt: Date?
    public var roomURL: String?
    public var notes: String
    public let createdAt: Date
    public var updatedAt: Date

    public enum SessionStatus: String, Codable, CaseIterable {
        case scheduled, active, ended, cancelled
    }

    public init(id: UUID = UUID(), title: String, participants: [String] = []) {
        self.id = id
        self.title = title
        self.participants = participants
        self.status = .scheduled
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Article model for SDK persistence.
public struct SDKArticle: SDKModel {
    public let id: UUID
    public var title: String
    public var content: String
    public var author: String
    public var tags: [String]
    public var isPublished: Bool
    public var wordCount: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, content: String, author: String = "", tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.author = author
        self.tags = tags
        self.isPublished = false
        self.wordCount = content.split(separator: " ").count
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// SDK App model for plugin/app registration.
public struct SDKAppDefinition: SDKModel {
    public let id: UUID
    public var name: String
    public var version: String
    public var author: String
    public var description: String
    public var permissions: [String]
    public var entryPoint: String
    public var isEnabled: Bool
    public var isSandboxed: Bool
    public var madeForWorkspace: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(), name: String, version: String = "1.0.0",
        author: String = "", description: String = "",
        permissions: [String] = [], entryPoint: String = ""
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.permissions = permissions
        self.entryPoint = entryPoint
        self.isEnabled = true
        self.isSandboxed = true
        self.madeForWorkspace = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
