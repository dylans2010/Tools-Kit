import Foundation

public class DeveloperProfileService: ObservableObject {
    public static let shared = DeveloperProfileService()

    @Published public var profile: DeveloperProfile = DeveloperProfile()

    private init() {
        loadProfile()
    }

    public func loadProfile() {
        // Awaiting backend integration
    }

    public func saveProfile(_ profile: DeveloperProfile) async throws {
        self.profile = profile
        // Awaiting backend integration
    }

    public func updateProfile(displayName: String, legalName: String, bio: String) async throws {
        var updated = profile
        updated.displayName = displayName
        updated.legalName = legalName
        updated.bio = bio
        try await saveProfile(updated)
    }

    public func fetchVerificationStatus() async throws -> DeveloperVerificationStatus {
        // Awaiting backend integration
        return profile.verificationStatus
    }

    public func computeProfileCompleteness() -> Double {
        let fields: [String] = [
            profile.displayName,
            profile.legalName,
            profile.username,
            profile.contactEmail,
            profile.bio
        ]
        let completed = fields.filter { !$0.isEmpty }.count
        return Double(completed) / Double(fields.count)
    }
}
