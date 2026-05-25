import Foundation

final class GamesPersistenceManager {
    static let shared = GamesPersistenceManager()

    private let defaults: UserDefaults
    private let profileKey = "games_player_profile"

    private init() {
        defaults = UserDefaults(suiteName: "group.tools-kit.games") ?? .standard
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    func load() -> PlayerProfile {
        guard let data = defaults.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data) else {
            return PlayerProfile.createDefault()
        }
        return profile
    }

    func reset() {
        let fresh = PlayerProfile.createDefault()
        save(fresh)
    }
}
