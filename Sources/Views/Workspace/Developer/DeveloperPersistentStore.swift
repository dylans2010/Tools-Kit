import Foundation
import Combine

public final class DeveloperPersistentStore: ObservableObject {
    public static let shared = DeveloperPersistentStore()

    private let profileKey = "com.toolskit.developer.profile"
    private let appsKey = "com.toolskit.developer.apps"
    private let keysKey = "com.toolskit.developer.keys"
    private let docsKey = "com.toolskit.developer.docs"
    private let webhooksKey = "com.toolskit.developer.webhooks"
    private let oauthClientsKey = "com.toolskit.developer.oauth"
    private let teamMembersKey = "com.toolskit.developer.team"
    private let sandboxesKey = "com.toolskit.developer.sandboxes"
    private let releasesKey = "com.toolskit.developer.releases"

    @Published public var profile: DeveloperProfile
    @Published public var apps: [DeveloperApp]
    @Published public var keys: [DeveloperKey]
    @Published public var docSections: [DocumentationSection]
    @Published public var webhooks: [DeveloperWebhook]
    @Published public var oauthClients: [OAuthClient]
    @Published public var teamMembers: [TeamMember]
    @Published public var sandboxes: [SandboxEnvironment]
    @Published public var releases: [AppRelease]

    private init() {
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
           let decoded = try? JSONDecoder().decode([DeveloperKey].self, from: data) {
            self.keys = decoded
        } else {
            self.keys = []
        }

        // Load Docs
        if let data = UserDefaults.standard.data(forKey: docsKey),
           let decoded = try? JSONDecoder().decode([DocumentationSection].self, from: data) {
            self.docSections = decoded
        } else {
            self.docSections = [
                DocumentationSection(title: "Getting Started", pages: [
                    DocPage(title: "Overview", content: "# Project Overview\nWelcome to your developer documentation.")
                ])
            ]
        }

        // Load Webhooks
        if let data = UserDefaults.standard.data(forKey: webhooksKey),
           let decoded = try? JSONDecoder().decode([DeveloperWebhook].self, from: data) {
            self.webhooks = decoded
        } else {
            self.webhooks = []
        }

        // Load OAuth
        if let data = UserDefaults.standard.data(forKey: oauthClientsKey),
           let decoded = try? JSONDecoder().decode([OAuthClient].self, from: data) {
            self.oauthClients = decoded
        } else {
            self.oauthClients = []
        }

        // Load Team
        if let data = UserDefaults.standard.data(forKey: teamMembersKey),
           let decoded = try? JSONDecoder().decode([TeamMember].self, from: data) {
            self.teamMembers = decoded
        } else {
            self.teamMembers = []
        }

        // Load Sandboxes
        if let data = UserDefaults.standard.data(forKey: sandboxesKey),
           let decoded = try? JSONDecoder().decode([SandboxEnvironment].self, from: data) {
            self.sandboxes = decoded
        } else {
            self.sandboxes = [
                SandboxEnvironment(name: "Development", apiBaseURL: "https://dev-api.toolskit.io", isActive: true),
                SandboxEnvironment(name: "Staging", apiBaseURL: "https://staging-api.toolskit.io")
            ]
        }

        // Load Releases
        if let data = UserDefaults.standard.data(forKey: releasesKey),
           let decoded = try? JSONDecoder().decode([AppRelease].self, from: data) {
            self.releases = decoded
        } else {
            self.releases = []
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

    public func saveKeys(_ newKeys: [DeveloperKey]) {
        if let encoded = try? JSONEncoder().encode(newKeys) {
            UserDefaults.standard.set(encoded, forKey: keysKey)
            self.keys = newKeys
        }
    }

    public func saveDocSections(_ newSections: [DocumentationSection]) {
        if let encoded = try? JSONEncoder().encode(newSections) {
            UserDefaults.standard.set(encoded, forKey: docsKey)
            self.docSections = newSections
        }
    }

    public func saveWebhooks(_ newWebhooks: [DeveloperWebhook]) {
        if let encoded = try? JSONEncoder().encode(newWebhooks) {
            UserDefaults.standard.set(encoded, forKey: webhooksKey)
            self.webhooks = newWebhooks
        }
    }

    public func saveOAuthClients(_ newClients: [OAuthClient]) {
        if let encoded = try? JSONEncoder().encode(newClients) {
            UserDefaults.standard.set(encoded, forKey: oauthClientsKey)
            self.oauthClients = newClients
        }
    }

    public func saveTeamMembers(_ newMembers: [TeamMember]) {
        if let encoded = try? JSONEncoder().encode(newMembers) {
            UserDefaults.standard.set(encoded, forKey: teamMembersKey)
            self.teamMembers = newMembers
        }
    }

    public func saveSandboxes(_ newSandboxes: [SandboxEnvironment]) {
        if let encoded = try? JSONEncoder().encode(newSandboxes) {
            UserDefaults.standard.set(encoded, forKey: sandboxesKey)
            self.sandboxes = newSandboxes
        }
    }

    public func saveReleases(_ newReleases: [AppRelease]) {
        if let encoded = try? JSONEncoder().encode(newReleases) {
            UserDefaults.standard.set(encoded, forKey: releasesKey)
            self.releases = newReleases
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
