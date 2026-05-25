import Foundation

struct PlayerProfile: Codable {
    var displayName: String
    var level: Int           // starts at 1
    var xp: Int              // current XP within level
    var xpToNextLevel: Int   // scales: level * 500
    var coins: Int           // universal in-game currency
    var gems: Int            // premium currency (earned via milestones, not purchasable)
    var gamesPlayed: Int
    var totalWins: Int
    var unlockedBadges: [String]
    var perGameStats: [String: GameStat]  // keyed by game identifier
}

struct GameStat: Codable {
    var highScore: Int
    var gamesPlayed: Int
    var wins: Int
    var personalBest: String?
}
