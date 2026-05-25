import Foundation

struct GameStat: Codable, Equatable {
    var highScore: Int
    var gamesPlayed: Int
    var wins: Int
    var personalBest: String?
}

struct PlayerProfile: Codable, Equatable {
    var displayName: String
    var level: Int
    var xp: Int
    var xpToNextLevel: Int
    var coins: Int
    var gems: Int
    var gamesPlayed: Int
    var totalWins: Int
    var unlockedBadges: [String]
    var perGameStats: [String: GameStat]

    static func createDefault() -> PlayerProfile {
        PlayerProfile(
            displayName: "Player",
            level: 1,
            xp: 0,
            xpToNextLevel: 500,
            coins: 500,
            gems: 0,
            gamesPlayed: 0,
            totalWins: 0,
            unlockedBadges: [],
            perGameStats: [:]
        )
    }

    mutating func recordGamePlayed(identifier: String, won: Bool, score: Int) {
        gamesPlayed += 1
        if won { totalWins += 1 }
        var stat = perGameStats[identifier] ?? GameStat(highScore: 0, gamesPlayed: 0, wins: 0, personalBest: nil)
        stat.gamesPlayed += 1
        if won { stat.wins += 1 }
        if score > stat.highScore { stat.highScore = score }
        perGameStats[identifier] = stat
    }
}
