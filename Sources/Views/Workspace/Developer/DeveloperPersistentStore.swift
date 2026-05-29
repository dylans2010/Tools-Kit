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
    @Published public var releases: [AppVersion]
    @Published public var logEntries: [LogEntry]
    @Published public var activities: [DeveloperActivityEvent]

    private let profileKey = "dev_portal_profile"
    private let appsKey = "dev_portal_apps"
    private let keysKey = "dev_portal_keys"
    private let webhooksKey = "dev_portal_webhooks"
    private let teamMembersKey = "dev_portal_team"
    private let organizationsKey = "dev_portal_orgs"
    private let submissionsKey = "dev_portal_submissions"
    private let releasesKey = "dev_portal_releases"
    private let logsKey = "dev_portal_logs"
    private let activitiesKey = "dev_portal_activities"

    private init() {
        // Initialize with real persisted data or empty defaults

        // Load Profile
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(DeveloperProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = DeveloperProfile()
        }

        // Load Apps
        if let data = UserDefaults.standard.data(forKey: appsKey),
           let decoded = try? JSONDecoder().decode([DeveloperApp].self, from: data) {
            self.apps = decoded
        } else {
            self.apps = []
        }

        // Load Keys
        if let data = UserDefaults.standard.data(forKey: keysKey),
           let decoded = try? JSONDecoder().decode([APIKey].self, from: data) {
            self.keys = decoded
        } else {
            self.keys = []
        }

        // Load Webhooks
        if let data = UserDefaults.standard.data(forKey: webhooksKey),
           let decoded = try? JSONDecoder().decode([WebhookEndpoint].self, from: data) {
            self.webhooks = decoded
        } else {
            self.webhooks = []
        }

        // Load Team
        if let data = UserDefaults.standard.data(forKey: teamMembersKey),
           let decoded = try? JSONDecoder().decode([OrgMember].self, from: data) {
            self.teamMembers = decoded
        } else {
            self.teamMembers = []
        }

        // Load Organizations
        if let data = UserDefaults.standard.data(forKey: organizationsKey),
           let decoded = try? JSONDecoder().decode([DeveloperOrganization].self, from: data) {
            self.organizations = decoded
        } else {
            self.organizations = []
        }

        // Load Submissions
        if let data = UserDefaults.standard.data(forKey: submissionsKey),
           let decoded = try? JSONDecoder().decode([MarketplaceSubmission].self, from: data) {
            self.submissions = decoded
        } else {
            self.submissions = []
        }

        // Load Releases
        if let data = UserDefaults.standard.data(forKey: releasesKey),
           let decoded = try? JSONDecoder().decode([AppVersion].self, from: data) {
            self.releases = decoded
        } else {
            self.releases = []
        }

        // Load Logs
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            self.logEntries = decoded
        } else {
            self.logEntries = []
        }

        // Load Activities
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let decoded = try? JSONDecoder().decode([DeveloperActivityEvent].self, from: data) {
            self.activities = decoded
        } else {
            self.activities = []
        }
    }

    public func saveProfile(_ newProfile: DeveloperProfile) {
        if let encoded = try? JSONEncoder().encode(newProfile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
            self.profile = newProfile
        }
    }

    public func saveApps(_ newApps: [DeveloperApp]) {
        if let encoded = try? JSONEncoder().encode(newApps) {
            UserDefaults.standard.set(encoded, forKey: appsKey)
            self.apps = newApps
        }
    }

    public func saveKeys(_ newKeys: [APIKey]) {
        if let encoded = try? JSONEncoder().encode(newKeys) {
            UserDefaults.standard.set(encoded, forKey: keysKey)
            self.keys = newKeys
        }
    }

    public func saveWebhooks(_ newWebhooks: [WebhookEndpoint]) {
        if let encoded = try? JSONEncoder().encode(newWebhooks) {
            UserDefaults.standard.set(encoded, forKey: webhooksKey)
            self.webhooks = newWebhooks
        }
    }

    public func saveTeamMembers(_ newMembers: [OrgMember]) {
        if let encoded = try? JSONEncoder().encode(newMembers) {
            UserDefaults.standard.set(encoded, forKey: teamMembersKey)
            self.teamMembers = newMembers
        }
    }

    public func saveOrganizations(_ newOrgs: [DeveloperOrganization]) {
        if let encoded = try? JSONEncoder().encode(newOrgs) {
            UserDefaults.standard.set(encoded, forKey: organizationsKey)
            self.organizations = newOrgs
        }
    }

    public func saveSubmissions(_ newSubmissions: [MarketplaceSubmission]) {
        if let encoded = try? JSONEncoder().encode(newSubmissions) {
            UserDefaults.standard.set(encoded, forKey: submissionsKey)
            self.submissions = newSubmissions
        }
    }

    public func saveReleases(_ newReleases: [AppVersion]) {
        if let encoded = try? JSONEncoder().encode(newReleases) {
            UserDefaults.standard.set(encoded, forKey: releasesKey)
            self.releases = newReleases
        }
    }

    public func saveLogs(_ newLogs: [LogEntry]) {
        if let encoded = try? JSONEncoder().encode(newLogs) {
            UserDefaults.standard.set(encoded, forKey: logsKey)
            self.logEntries = newLogs
        }
    }

    public func saveActivities(_ newActivities: [DeveloperActivityEvent]) {
        if let encoded = try? JSONEncoder().encode(newActivities) {
            UserDefaults.standard.set(encoded, forKey: activitiesKey)
            self.activities = newActivities
        }
    }

    public func addApp(_ app: DeveloperApp) {
        var currentApps = apps
        currentApps.append(app)
        saveApps(currentApps)
    }

    public func deleteApp(id: UUID) {
        let currentApps = apps.filter { $0.id != id }
        saveApps(currentApps)
    }
}
