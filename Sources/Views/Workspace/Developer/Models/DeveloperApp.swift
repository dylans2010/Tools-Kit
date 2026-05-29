import Foundation

public enum DeveloperAppType: String, Codable, CaseIterable {
    case app = "App"
    case plugin = "Plugin"
    case connector = "Connector"
    case service = "Service"
    case sdkExtension = "SDK Extension"
}

public enum DeveloperAppStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case underReview = "Under Review"
    case live = "Live"
    case suspended = "Suspended"
    case deprecated = "Deprecated"
    case archived = "Archived"
}

public struct AppStatusEvent: Codable, Identifiable, Hashable {
    public var id: UUID
    public var status: DeveloperAppStatus
    public var timestamp: Date
    public var reason: String

    public init(id: UUID = UUID(), status: DeveloperAppStatus, timestamp: Date = Date(), reason: String = "") {
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.reason = reason
    }
}

public struct AppVersion: Codable, Identifiable, Hashable {
    public var id: UUID
    public var version: String
    public var buildNumber: String
    public var releaseNotes: String
    public var createdAt: Date
    public var status: String // e.g. "Draft", "Released"
    public var rolloutPercentage: Double

    public init(id: UUID = UUID(), version: String, buildNumber: String, releaseNotes: String = "", createdAt: Date = Date(), status: String = "Draft", rolloutPercentage: Double = 0.0) {
        self.id = id
        self.version = version
        self.buildNumber = buildNumber
        self.releaseNotes = releaseNotes
        self.createdAt = createdAt
        self.status = status
        self.rolloutPercentage = rolloutPercentage
    }
}

public struct AppCollaborator: Codable, Identifiable, Hashable {
    public var id: UUID
    public var accountID: UUID
    public var name: String
    public var email: String
    public var role: String // e.g. "Owner", "Developer"

    public init(id: UUID = UUID(), accountID: UUID, name: String, email: String, role: String) {
        self.id = id
        self.accountID = accountID
        self.name = name
        self.email = email
        self.role = role
    }
}

public struct AppEnvironment: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var apiBaseURL: String
    public var assignedKeyIDs: [UUID]

    public init(id: UUID = UUID(), name: String, apiBaseURL: String, assignedKeyIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.apiBaseURL = apiBaseURL
        self.assignedKeyIDs = assignedKeyIDs
    }
}

public enum MonetizationModel: String, Codable, CaseIterable {
    case free = "Free"
    case freemium = "Freemium"
    case subscription = "Subscription"
    case oneTimePurchase = "One-time Purchase"
}

public struct PricingConfig: Codable, Hashable {
    public var currency: String
    public var amount: Double
    public var interval: String? // "monthly", "yearly"

    public init(currency: String = "USD", amount: Double = 0.0, interval: String? = nil) {
        self.currency = currency
        self.amount = amount
        self.interval = interval
    }
}

public enum PlatformTarget: String, Codable, CaseIterable {
    case macos = "macOS"
    case ios = "iOS"
    case web = "Web"
    case linux = "Linux"
}

public struct DeveloperApp: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: DeveloperAppType
    public var status: DeveloperAppStatus
    public var version: String
    public var description: String
    public var aboutInfo: String
    public var credits: String
    public var socialLinks: [String: String]
    public var iconName: String
    public var bundleId: String
    public var installCount: Int
    public var createdAt: Date
    public var lastModified: Date
    public var monetizationModel: MonetizationModel
    public var pricingConfig: PricingConfig
    public var revenue: Double
    public var versions: [AppVersion]
    public var collaborators: [AppCollaborator]
    public var environments: [AppEnvironment]
    public var grantedScopes: [String]
    public var pendingScopeRequests: [UUID]
    public var platformTargets: [PlatformTarget]
    public var currentVersion: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        type: DeveloperAppType,
        status: DeveloperAppStatus = .draft,
        version: String = "1.0.0",
        description: String = "",
        aboutInfo: String = "",
        credits: String = "",
        socialLinks: [String: String] = [:],
        iconName: String = "app.dashed",
        bundleId: String = "",
        installCount: Int = 0,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        monetizationModel: MonetizationModel = .free,
        pricingConfig: PricingConfig = PricingConfig(),
        revenue: Double = 0.0,
        versions: [AppVersion] = [],
        collaborators: [AppCollaborator] = [],
        environments: [AppEnvironment] = [],
        grantedScopes: [String] = [],
        pendingScopeRequests: [UUID] = [],
        platformTargets: [PlatformTarget] = [.macos],
        currentVersion: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.version = version
        self.description = description
        self.aboutInfo = aboutInfo
        self.credits = credits
        self.socialLinks = socialLinks
        self.iconName = iconName
        self.bundleId = bundleId
        self.installCount = installCount
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.monetizationModel = monetizationModel
        self.pricingConfig = pricingConfig
        self.revenue = revenue
        self.versions = versions
        self.collaborators = collaborators
        self.environments = environments
        self.grantedScopes = grantedScopes
        self.pendingScopeRequests = pendingScopeRequests
        self.platformTargets = platformTargets
        self.currentVersion = currentVersion
    }
}
