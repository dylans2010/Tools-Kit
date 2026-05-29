import Foundation

public enum SubmissionStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case pendingReview = "Pending Review"
    case underReview = "Under Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case live = "Live"
    case paused = "Paused"
    case deprecated = "Deprecated"
}

public struct SubmissionStatusEvent: Codable, Identifiable, Hashable {
    public var id: UUID
    public var status: SubmissionStatus
    public var timestamp: Date
    public var actorID: UUID?
    public var reason: String

    public init(id: UUID = UUID(), status: SubmissionStatus, timestamp: Date = Date(), actorID: UUID? = nil, reason: String = "") {
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.actorID = actorID
        self.reason = reason
    }
}

public struct ListingMetadata: Codable, Hashable {
    public var title: String
    public var subtitle: String
    public var description: String
    public var categories: [String]
    public var keywords: [String]

    public init(title: String = "", subtitle: String = "", description: String = "", categories: [String] = [], keywords: [String] = []) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.categories = categories
        self.keywords = keywords
    }
}

public struct ListingAssets: Codable, Hashable {
    public var iconURL: String
    public var screenshotURLs: [String]
    public var previewVideoURL: String

    public init(iconURL: String = "", screenshotURLs: [String] = [], previewVideoURL: String = "") {
        self.iconURL = iconURL
        self.screenshotURLs = screenshotURLs
        self.previewVideoURL = previewVideoURL
    }
}

public struct ListingTechnicalDetails: Codable, Hashable {
    public var version: String
    public var buildNumber: String
    public var minOSVersion: String
    public var releaseNotes: String

    public init(version: String = "", buildNumber: String = "", minOSVersion: String = "", releaseNotes: String = "") {
        self.version = version
        self.buildNumber = buildNumber
        self.minOSVersion = minOSVersion
        self.releaseNotes = releaseNotes
    }
}

public struct SupportConfig: Codable, Hashable {
    public var supportEmail: String
    public var supportURL: String
    public var marketingURL: String
    public var privacyPolicyURL: String

    public init(supportEmail: String = "", supportURL: String = "", marketingURL: String = "", privacyPolicyURL: String = "") {
        self.supportEmail = supportEmail
        self.supportURL = supportURL
        self.marketingURL = marketingURL
        self.privacyPolicyURL = privacyPolicyURL
    }
}

public struct DataHandlingDeclaration: Codable, Hashable {
    public var collectsUserData: Bool
    public var dataTypesCollected: [String]
    public var sharesWithThirdParties: Bool
    public var usesEncryption: Bool

    public init(collectsUserData: Bool = false, dataTypesCollected: [String] = [], sharesWithThirdParties: Bool = false, usesEncryption: Bool = false) {
        self.collectsUserData = collectsUserData
        self.dataTypesCollected = dataTypesCollected
        self.sharesWithThirdParties = sharesWithThirdParties
        self.usesEncryption = usesEncryption
    }
}

public struct ReviewFeedbackItem: Codable, Identifiable, Hashable {
    public var id: UUID
    public var category: String
    public var severity: String // "Blocking", "Warning"
    public var note: String
    public var timestamp: Date
    public var isResolved: Bool

    public init(id: UUID = UUID(), category: String, severity: String, note: String, timestamp: Date = Date(), isResolved: Bool = false) {
        self.id = id
        self.category = category
        self.severity = severity
        self.note = note
        self.timestamp = timestamp
        self.isResolved = isResolved
    }
}

public struct ReviewResponse: Codable, Identifiable, Hashable {
    public var id: UUID
    public var feedbackItemID: UUID
    public var message: String
    public var timestamp: Date

    public init(id: UUID = UUID(), feedbackItemID: UUID, message: String, timestamp: Date = Date()) {
        self.id = id
        self.feedbackItemID = feedbackItemID
        self.message = message
        self.timestamp = timestamp
    }
}

public struct MarketplaceSubmissionDraft: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var metadata: ListingMetadata
    public var assets: ListingAssets
    public var technicalDetails: ListingTechnicalDetails
    public var supportConfig: SupportConfig
    public var dataHandling: DataHandlingDeclaration
    public var declaredScopeIdentifiers: [String]
    public var lastSavedAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        metadata: ListingMetadata = ListingMetadata(),
        assets: ListingAssets = ListingAssets(),
        technicalDetails: ListingTechnicalDetails = ListingTechnicalDetails(),
        supportConfig: SupportConfig = SupportConfig(),
        dataHandling: DataHandlingDeclaration = DataHandlingDeclaration(),
        declaredScopeIdentifiers: [String] = [],
        lastSavedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.metadata = metadata
        self.assets = assets
        self.technicalDetails = technicalDetails
        self.supportConfig = supportConfig
        self.dataHandling = dataHandling
        self.declaredScopeIdentifiers = declaredScopeIdentifiers
        self.lastSavedAt = lastSavedAt
    }
}

public struct MarketplaceSubmission: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var status: SubmissionStatus
    public var submittedAt: Date
    public var statusHistory: [SubmissionStatusEvent]
    public var reviewFeedback: [ReviewFeedbackItem]
    public var reviewResponses: [ReviewResponse]
    // Snapshot of data at submission time
    public var metadata: ListingMetadata
    public var assets: ListingAssets
    public var technicalDetails: ListingTechnicalDetails
    public var supportConfig: SupportConfig
    public var dataHandling: DataHandlingDeclaration

    public init(
        id: UUID = UUID(),
        appID: UUID,
        status: SubmissionStatus = .pendingReview,
        submittedAt: Date = Date(),
        statusHistory: [SubmissionStatusEvent] = [],
        reviewFeedback: [ReviewFeedbackItem] = [],
        reviewResponses: [ReviewResponse] = [],
        metadata: ListingMetadata,
        assets: ListingAssets,
        technicalDetails: ListingTechnicalDetails,
        supportConfig: SupportConfig,
        dataHandling: DataHandlingDeclaration
    ) {
        self.id = id
        self.appID = appID
        self.status = status
        self.submittedAt = submittedAt
        self.statusHistory = statusHistory
        self.reviewFeedback = reviewFeedback
        self.reviewResponses = reviewResponses
        self.metadata = metadata
        self.assets = assets
        self.technicalDetails = technicalDetails
        self.supportConfig = supportConfig
        self.dataHandling = dataHandling
    }
}
