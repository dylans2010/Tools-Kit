import Foundation
import Combine

public final class DeveloperPersistentStore: ObservableObject {
    public static let shared = DeveloperPersistentStore()

    private let profileKey = "com.toolskit.developer.profile"
    private let appsKey = "com.toolskit.developer.apps"
    private let keysKey = "com.toolskit.developer.keys"

    @Published public var profile: DeveloperProfile
    @Published public var apps: [DeveloperApp]
    @Published public var keys: [DeveloperKey]

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
