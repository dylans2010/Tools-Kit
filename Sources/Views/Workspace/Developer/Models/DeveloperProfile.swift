import Foundation

public enum DeveloperTier: String, Codable, CaseIterable {
    case community = "Community"
    case registered = "Registered"
    case verified = "Verified"
    case enterprise = "Enterprise"
}

public enum DeveloperVerificationStatus: String, Codable, CaseIterable {
    case unverified = "Unverified"
    case pending = "Pending"
    case verified = "Verified"
    case rejected = "Rejected"
}

public enum ProfileFieldVisibility: String, Codable, CaseIterable {
    case `public` = "Public"
    case `private` = "Private"
    case teamOnly = "Team Only"
}

public struct DeveloperLink: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var url: String

    public init(id: UUID = UUID(), title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}

public struct DeveloperAddress: Codable, Hashable {
    public var street: String
    public var city: String
    public var state: String
    public var postalCode: String
    public var country: String

    public init(street: String = "", city: String = "", state: String = "", postalCode: String = "", country: String = "") {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
}

public struct DeveloperProfile: Codable {
    public var id: UUID
    public var displayName: String
    public var legalName: String
    public var username: String
    public var pronouns: String
    public var avatarUrl: String // Not optional as per requirements, can be empty string
    public var bio: String
    public var experience: String
    public var credits: String
    public var organization: String
    public var website: String
    public var github: String
    public var linkedin: String
    public var socialLinks: [String: String]
    public var contactEmail: String
    public var supportEmail: String
    public var isPublic: Bool
    public var tier: DeveloperTier
    public var verificationStatus: DeveloperVerificationStatus
    public var joinedDate: Date
    public var lastActive: Date
    public var skills: [String]
    public var preferredLanguages: [String]
    public var address: DeveloperAddress
    public var fieldVisibility: [String: ProfileFieldVisibility]

    public init(
        id: UUID = UUID(),
        displayName: String = "",
        legalName: String = "",
        username: String = "",
        pronouns: String = "",
        avatarUrl: String = "",
        bio: String = "",
        experience: String = "",
        credits: String = "",
        organization: String = "",
        website: String = "",
        github: String = "",
        linkedin: String = "",
        socialLinks: [String: String] = [:],
        contactEmail: String = "",
        supportEmail: String = "",
        isPublic: Bool = false,
        tier: DeveloperTier = .community,
        verificationStatus: DeveloperVerificationStatus = .unverified,
        joinedDate: Date = Date(),
        lastActive: Date = Date(),
        skills: [String] = [],
        preferredLanguages: [String] = [],
        address: DeveloperAddress = DeveloperAddress(),
        fieldVisibility: [String: ProfileFieldVisibility] = [:]
    ) {
        self.id = id
        self.displayName = displayName
        self.legalName = legalName
        self.username = username
        self.pronouns = pronouns
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.experience = experience
        self.credits = credits
        self.organization = organization
        self.website = website
        self.github = github
        self.linkedin = linkedin
        self.socialLinks = socialLinks
        self.contactEmail = contactEmail
        self.supportEmail = supportEmail
        self.isPublic = isPublic
        self.tier = tier
        self.verificationStatus = verificationStatus
        self.joinedDate = joinedDate
        self.lastActive = lastActive
        self.skills = skills
        self.preferredLanguages = preferredLanguages
        self.address = address
        self.fieldVisibility = fieldVisibility
    }
}
