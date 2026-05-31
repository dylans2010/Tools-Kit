import Foundation
import SwiftUI

public enum TeamRole: String, Codable, CaseIterable {
    case owner, admin, developer, viewer
    public var color: Color {
        switch self {
            case .owner: return .purple
            case .admin: return .blue
            case .developer: return .green
            case .viewer: return .gray
        }
    }
}

public enum OrgRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case admin = "Admin"
    case billing = "Billing"
    case developer = "Developer"
    case member = "Member"

    public var color: Color {
        switch self {
        case .owner: return .purple
        case .admin: return .blue
        case .billing: return .orange
        case .developer: return .green
        case .member: return .gray
        }
    }
}

public struct OrgMember: Identifiable, Codable, Hashable {
    public var id: UUID
    public var accountID: UUID
    public var name: String
    public var email: String
    public var role: OrgRole
    public var joinedAt: Date

    public init(id: UUID = UUID(), accountID: UUID, name: String, email: String, role: OrgRole, joinedAt: Date = Date()) {
        self.id = id
        self.accountID = accountID
        self.name = name
        self.email = email
        self.role = role
        self.joinedAt = joinedAt
    }
}

public struct TeamMember: Identifiable, Codable, Hashable {
    public var id: UUID
    public var accountID: UUID
    public var name: String
    public var email: String
    public var role: TeamRole

    public init(id: UUID = UUID(), accountID: UUID, name: String, email: String, role: TeamRole) {
        self.id = id
        self.accountID = accountID
        self.name = name
        self.email = email
        self.role = role
    }
}

public struct DeveloperTeam: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var organizationID: UUID
    public var members: [TeamMember]
    public var appAccessIDs: [UUID]

    public init(id: UUID = UUID(), name: String, organizationID: UUID, members: [TeamMember] = [], appAccessIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.organizationID = organizationID
        self.members = members
        self.appAccessIDs = appAccessIDs
    }
}

public struct DeveloperOrganization: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var legalName: String
    public var website: String
    public var members: [OrgMember]
    public var teams: [DeveloperTeam]

    public init(id: UUID = UUID(), name: String, legalName: String = "", website: String = "", members: [OrgMember] = [], teams: [DeveloperTeam] = []) {
        self.id = id
        self.name = name
        self.legalName = legalName
        self.website = website
        self.members = members
        self.teams = teams
    }
}
