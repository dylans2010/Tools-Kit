import Foundation

public class DeveloperProfileService: ObservableObject {
    public static let shared = DeveloperProfileService()
    private let store = DeveloperPersistentStore.shared

    @Published public var profile: DeveloperProfile = DeveloperProfile()

    private init() {
        loadProfile()
    }

    public func loadProfile() {
        self.profile = store.profile
    }

    public func saveProfile(_ profile: DeveloperProfile) async throws {
        store.saveProfile(profile)
        await MainActor.run {
            self.profile = profile
        }
    }

    public func updateProfile(displayName: String, legalName: String, bio: String) async throws {
        var updated = profile
        updated.displayName = displayName
        updated.legalName = legalName
        updated.bio = bio
        try await saveProfile(updated)
    }

    public func fetchVerificationStatus() async throws -> DeveloperVerificationStatus {
        // Logic to re-verify status if needed
        return profile.verificationStatus
    }

    public func computeProfileCompleteness() -> Double {
        let fields: [String] = [
            profile.displayName,
            profile.legalName,
            profile.username,
            profile.contactEmail,
            profile.bio,
            profile.website,
            profile.github
        ]
        let completed = fields.filter { !$0.isEmpty }.count
        return Double(completed) / Double(fields.count)
    }
}
