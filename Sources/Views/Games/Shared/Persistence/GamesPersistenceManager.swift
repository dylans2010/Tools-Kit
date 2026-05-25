import Foundation

class GamesPersistenceManager {
    static let shared = GamesPersistenceManager()
    private let suiteName = "group.tools-kit.games"
    private let profileKey = "player_profile"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    func save(_ profile: PlayerProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: profileKey)
            defaults.synchronize()
        }
    }

    func load() -> PlayerProfile {
        if let data = defaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            return profile
        }
        return createDefaultProfile()
    }

    private func createDefaultProfile() -> PlayerProfile {
        PlayerProfile(
            displayName: "Player",
            level: 1,
            xp: 0,
            xpToNextLevel: 500,
            coins: 1000,
            gems: 0,
            gamesPlayed: 0,
            totalWins: 0,
            unlockedBadges: [],
            perGameStats: [:]
        )
    }
}
