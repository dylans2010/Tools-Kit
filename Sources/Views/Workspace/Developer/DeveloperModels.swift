import Foundation
import SwiftUI

// MARK: - Developer Identity

public enum DeveloperTier: String, Codable, CaseIterable {
    case community = "Community"
    case registered = "Registered"
    case verified = "Verified"
    case enterprise = "Enterprise"
}

public struct DeveloperProfile: Codable {
    public var displayName: String
    public var legalName: String
    public var username: String
    public var pronouns: String
    public var avatarUrl: String?
    public var bio: String
    public var website: String
    public var github: String
    public var linkedin: String
    public var contactEmail: String
    public var supportEmail: String
    public var isPublic: Bool
    public var tier: DeveloperTier
    public var joinedDate: Date
    public var lastActive: Date
    public var skills: [String]
    public var preferredLanguages: [String]

    public init(
        displayName: String = "",
        legalName: String = "",
        username: String = "",
        pronouns: String = "",
        bio: String = "",
        website: String = "",
        github: String = "",
        linkedin: String = "",
        contactEmail: String = "",
        supportEmail: String = "",
        isPublic: Bool = false,
        tier: DeveloperTier = .community,
        joinedDate: Date = Date(),
        lastActive: Date = Date(),
        skills: [String] = [],
        preferredLanguages: [String] = []
    ) {
        self.displayName = displayName
        self.legalName = legalName
        self.username = username
        self.pronouns = pronouns
        self.bio = bio
        self.website = website
        self.github = github
        self.linkedin = linkedin
        self.contactEmail = contactEmail
        self.supportEmail = supportEmail
        self.isPublic = isPublic
        self.tier = tier
        self.joinedDate = joinedDate
        self.lastActive = lastActive
        self.skills = skills
        self.preferredLanguages = preferredLanguages
    }
}

// MARK: - App Management

public enum AppStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case underReview = "Under Review"
    case live = "Live"
    case suspended = "Suspended"
    case deprecated = "Deprecated"

    public var color: Color {
        switch self {
        case .draft: return .gray
        case .underReview: return .orange
        case .live: return .green
        case .suspended: return .red
        case .deprecated: return .secondary
        }
    }
}

public enum AppType: String, Codable, CaseIterable {
    case app = "App"
    case plugin = "Plugin"
    case connector = "Connector"
    case service = "Service"
    case sdkExtension = "SDK Extension"
}

public struct DeveloperApp: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var type: AppType
    public var status: AppStatus
    public var version: String
    public var description: String
    public var iconName: String
    public var bundleId: String
    public var installCount: Int
    public var createdAt: Date
    public var lastModified: Date
    public var pricingModel: String
    public var revenue: Double

    public init(
        id: UUID = UUID(),
        name: String,
        type: AppType,
        status: AppStatus = .draft,
        version: String = "1.0.0",
        description: String = "",
        iconName: String = "app.dashed",
        bundleId: String = "",
        installCount: Int = 0,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        pricingModel: String = "Free",
        revenue: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.version = version
        self.description = description
        self.iconName = iconName
        self.bundleId = bundleId
        self.installCount = installCount
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.pricingModel = pricingModel
        self.revenue = revenue
    }
}

// MARK: - Scope Management

public enum ScopeRiskLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

public struct DeveloperScope: Identifiable, Codable {
    public var id: String
    public var name: String
    public var description: String
    public var riskLevel: ScopeRiskLevel
    public var category: String
    public var requiredTier: DeveloperTier

    public init(id: String, name: String, description: String, riskLevel: ScopeRiskLevel, category: String, requiredTier: DeveloperTier = .community) {
        self.id = id
        self.name = name
        self.description = description
        self.riskLevel = riskLevel
        self.category = category
        self.requiredTier = requiredTier
    }
}

public struct ScopeRequest: Identifiable, Codable {
    public var id: UUID
    public var appId: UUID
    public var scopeId: String
    public var justification: String
    public var status: RequestStatus
    public var requestedAt: Date

    public enum RequestStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
    }
}

// MARK: - Auth Management

public enum AuthProviderType: String, Codable, CaseIterable {
    case oauth2 = "OAuth 2.0"
    case apiKey = "API Key"
    case jwt = "JWT"
    case saml = "SAML"
    case custom = "Custom"
}

public struct AuthProviderConfig: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var type: AuthProviderType
    public var lastValidated: Date
    public var status: ConfigStatus

    public enum ConfigStatus: String, Codable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
    }
}

// MARK: - Logging

public enum LogSeverity: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    case critical = "CRITICAL"

    public var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

public struct DeveloperLogEntry: Identifiable, Codable {
    public var id: UUID
    public var timestamp: Date
    public var severity: LogSeverity
    public var source: String
    public var eventType: String
    public var message: String
    public var payload: String?
}

// MARK: - Analytics

public struct AppAnalytics: Codable {
    public var totalInstalls: Int
    public var activeUsers: Int
    public var crashFreeSessions: Double
    public var apiCallVolume: Int
    public var dailyActiveUsers: [Int] // Last 30 days
    public var revenueByDay: [Double]
}

// MARK: - Documentation

public struct DocPage: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var content: String
    public var lastModified: Date
    public var version: String
    public var isDraft: Bool
}
