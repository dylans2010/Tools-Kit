import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

struct AppLockProfile: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var selection: FamilyActivitySelection
    var isActive: Bool

    init(id: String = UUID().uuidString, name: String, selection: FamilyActivitySelection = FamilyActivitySelection(), isActive: Bool = false) {
        self.id = id
        self.name = name
        self.selection = selection
        self.isActive = isActive
    }
}

@MainActor
class AppLockManager: ObservableObject {
    nonisolated(unsafe) static let shared = AppLockManager()

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    @Published var profiles: [AppLockProfile] = [] {
        didSet {
            saveProfiles()
        }
    }

    private let profilesKey = "com.toolskit.applock.profiles"

    private init() {
        loadProfiles()

        // Ensure restrictions are in sync with active profiles
        syncRestrictions()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    // MARK: - Profile Management

    func createProfile(name: String) {
        let newProfile = AppLockProfile(name: name)
        profiles.append(newProfile)
    }

    func deleteProfile(id: String) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            if profiles[index].isActive {
                endSession(for: id)
            }
            profiles.remove(at: index)
        }
    }

    func updateProfile(_ updatedProfile: AppLockProfile) {
        if let index = profiles.firstIndex(where: { $0.id == updatedProfile.id }) {
            profiles[index] = updatedProfile
            if updatedProfile.isActive {
                applyRestrictions()
            }
        }
    }

    // MARK: - Session Management

    func startSession(for profileId: String) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].isActive = true
            applyRestrictions()
            startMonitoring(for: profiles[index])
        }
    }

    func endSession(for profileId: String) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].isActive = false
            syncRestrictions()
            stopMonitoring(for: profileId)
        }
    }

    // MARK: - Internal Logic

    private func syncRestrictions() {
        if profiles.contains(where: { $0.isActive }) {
            applyRestrictions()
        } else {
            clearRestrictions()
        }
    }

    private func applyRestrictions() {
        var aggregateSelection = FamilyActivitySelection()

        for profile in profiles where profile.isActive {
            // Merging selections
            // Note: FamilyActivitySelection doesn't support easy merging of tokens directly without set operations on its properties
            aggregateSelection.applicationTokens.formUnion(profile.selection.applicationTokens)
            aggregateSelection.categoryTokens.formUnion(profile.selection.categoryTokens)
            aggregateSelection.webDomainTokens.formUnion(profile.selection.webDomainTokens)
        }

        store.shield.applications = aggregateSelection.applicationTokens
        store.shield.applicationCategories = .specific(aggregateSelection.categoryTokens)
    }

    private func clearRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    private func startMonitoring(for profile: AppLockProfile) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let name = DeviceActivityName("com.toolskit.applock.activity.\(profile.id)")

        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            print("Failed to start monitoring for \(profile.id): \(error)")
        }
    }

    private func stopMonitoring(for profileId: String) {
        center.stopMonitoring([DeviceActivityName("com.toolskit.applock.activity.\(profileId)")])
    }

    // MARK: - Persistence

    private func saveProfiles() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([AppLockProfile].self, from: data) {
                self.profiles = decoded
            }
        }
    }
}
