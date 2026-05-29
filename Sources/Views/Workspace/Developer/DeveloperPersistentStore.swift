import Foundation
import Combine

public class DeveloperPersistentStore: ObservableObject {
    public static let shared = DeveloperPersistentStore()

    @Published public var profile: DeveloperProfile
    @Published public var apps: [DeveloperApp]
    @Published public var keys: [APIKey]
    @Published public var webhooks: [WebhookEndpoint]
    @Published public var teamMembers: [OrgMember]
    @Published public var organizations: [DeveloperOrganization]
    @Published public var submissions: [MarketplaceSubmission]
    @Published public var drafts: [MarketplaceSubmissionDraft]
    @Published public var releases: [AppVersion]
    @Published public var logEntries: [LogEntry]
    @Published public var activities: [DeveloperActivityEvent]
    @Published public var grantedScopes: [GrantedScope]
    @Published public var scopeRequests: [ScopeRequest]
    @Published public var scopeAuditLogs: [ScopeAuditEvent]
    @Published public var documentationPages: [DocumentationPage]
    @Published public var certificates: [DeveloperCertificate]
    @Published public var betaGroups: [BetaGroup]
    @Published public var supportTickets: [SupportTicket]

    private let profileKey = "dev_portal_profile"
    private let appsKey = "dev_portal_apps"
    private let keysKey = "dev_portal_keys"
    private let webhooksKey = "dev_portal_webhooks"
    private let teamMembersKey = "dev_portal_team"
    private let organizationsKey = "dev_portal_orgs"
    private let submissionsKey = "dev_portal_submissions"
    private let draftsKey = "dev_portal_drafts"
    private let releasesKey = "dev_portal_releases"
    private let logsKey = "dev_portal_logs"
    private let activitiesKey = "dev_portal_activities"
    private let grantedScopesKey = "dev_portal_granted_scopes"
    private let scopeRequestsKey = "dev_portal_scope_requests"
    private let scopeAuditLogsKey = "dev_portal_scope_audit_logs"
    private let documentationKey = "dev_portal_documentation"
    private let certificatesKey = "dev_portal_certificates"
    private let betaGroupsKey = "dev_portal_beta_groups"
    private let supportTicketsKey = "dev_portal_support_tickets"

    private init() {
        self.profile = Self.load(DeveloperProfile.self, key: profileKey) ?? DeveloperProfile()
        self.apps = Self.load([DeveloperApp].self, key: appsKey) ?? []
        self.keys = Self.load([APIKey].self, key: keysKey) ?? []
        self.webhooks = Self.load([WebhookEndpoint].self, key: webhooksKey) ?? []
        self.teamMembers = Self.load([OrgMember].self, key: teamMembersKey) ?? []
        self.organizations = Self.load([DeveloperOrganization].self, key: organizationsKey) ?? []
        self.submissions = Self.load([MarketplaceSubmission].self, key: submissionsKey) ?? []
        self.drafts = Self.load([MarketplaceSubmissionDraft].self, key: draftsKey) ?? []
        self.releases = Self.load([AppVersion].self, key: releasesKey) ?? []
        self.logEntries = Self.load([LogEntry].self, key: logsKey) ?? []
        self.activities = Self.load([DeveloperActivityEvent].self, key: activitiesKey) ?? []
        self.grantedScopes = Self.load([GrantedScope].self, key: grantedScopesKey) ?? []
        self.scopeRequests = Self.load([ScopeRequest].self, key: scopeRequestsKey) ?? []
        self.scopeAuditLogs = Self.load([ScopeAuditEvent].self, key: scopeAuditLogsKey) ?? []
        self.documentationPages = Self.load([DocumentationPage].self, key: documentationKey) ?? []
        self.certificates = Self.load([DeveloperCertificate].self, key: certificatesKey) ?? []
        self.betaGroups = Self.load([BetaGroup].self, key: betaGroupsKey) ?? []
        self.supportTickets = Self.load([SupportTicket].self, key: supportTicketsKey) ?? []
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }

    private func save<T: Encodable>(_ object: T, key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    public func saveProfile(_ newProfile: DeveloperProfile) {
        save(newProfile, key: profileKey)
        self.profile = newProfile
    }

    public func saveApps(_ newApps: [DeveloperApp]) {
        save(newApps, key: appsKey)
        self.apps = newApps
    }

    public func addApp(_ app: DeveloperApp) {
        self.apps.append(app)
        save(self.apps, key: appsKey)
    }

    public func saveKeys(_ newKeys: [APIKey]) {
        save(newKeys, key: keysKey)
        self.keys = newKeys
    }

    public func saveWebhooks(_ newWebhooks: [WebhookEndpoint]) {
        save(newWebhooks, key: webhooksKey)
        self.webhooks = newWebhooks
    }

    public func saveTeamMembers(_ newMembers: [OrgMember]) {
        save(newMembers, key: teamMembersKey)
        self.teamMembers = newMembers
    }

    public func saveOrganizations(_ newOrgs: [DeveloperOrganization]) {
        save(newOrgs, key: organizationsKey)
        self.organizations = newOrgs
    }

    public func saveSubmissions(_ newSubmissions: [MarketplaceSubmission]) {
        save(newSubmissions, key: submissionsKey)
        self.submissions = newSubmissions
    }

    public func saveDrafts(_ newDrafts: [MarketplaceSubmissionDraft]) {
        save(newDrafts, key: draftsKey)
        self.drafts = newDrafts
    }

    public func saveReleases(_ newReleases: [AppVersion]) {
        save(newReleases, key: releasesKey)
        self.releases = newReleases
    }

    public func saveLogs(_ newLogs: [LogEntry]) {
        save(newLogs, key: logsKey)
        self.logEntries = newLogs
    }

    public func saveActivities(_ newActivities: [DeveloperActivityEvent]) {
        save(newActivities, key: activitiesKey)
        self.activities = newActivities
    }

    public func saveGrantedScopes(_ newScopes: [GrantedScope]) {
        save(newScopes, key: grantedScopesKey)
        self.grantedScopes = newScopes
    }

    public func saveScopeRequests(_ newRequests: [ScopeRequest]) {
        save(newRequests, key: scopeRequestsKey)
        self.scopeRequests = newRequests
    }

    public func saveScopeAuditLogs(_ newLogs: [ScopeAuditEvent]) {
        save(newLogs, key: scopeAuditLogsKey)
        self.scopeAuditLogs = newLogs
    }

    public func saveDocumentationPages(_ newPages: [DocumentationPage]) {
        save(newPages, key: documentationKey)
        self.documentationPages = newPages
    }

    public func saveCertificates(_ newCertificates: [DeveloperCertificate]) {
        save(newCertificates, key: certificatesKey)
        self.certificates = newCertificates
    }

    public func saveBetaGroups(_ newGroups: [BetaGroup]) {
        save(newGroups, key: betaGroupsKey)
        self.betaGroups = newGroups
    }

    public func saveSupportTickets(_ newTickets: [SupportTicket]) {
        save(newTickets, key: supportTicketsKey)
        self.supportTickets = newTickets
    }
}

public struct DeveloperCertificate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var name: String
    public var type: String
    public var createdAt: Date
    public var expiresAt: Date

    public init(id: UUID = UUID(), appID: UUID, name: String, type: String, createdAt: Date = Date(), expiresAt: Date = Date().addingTimeInterval(365*24*3600)) {
        self.id = id
        self.appID = appID
        self.name = name
        self.type = type
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

public struct BetaGroup: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var name: String
    public var testerEmails: [String]

    public init(id: UUID = UUID(), appID: UUID, name: String, testerEmails: [String] = []) {
        self.id = id
        self.appID = appID
        self.name = name
        self.testerEmails = testerEmails
    }
}

public struct SupportTicket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var subject: String
    public var topic: String
    public var message: String
    public var status: String
    public var createdAt: Date

    public init(id: UUID = UUID(), subject: String, topic: String, message: String, status: String = "Open", createdAt: Date = Date()) {
        self.id = id
        self.subject = subject
        self.topic = topic
        self.message = message
        self.status = status
        self.createdAt = createdAt
    }
}
