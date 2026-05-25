import Foundation

struct GameStat: Codable, Equatable {
    var highScore: Int
    var gamesPlayed: Int
    var wins: Int
    var personalBest: String?
    var currentStreak: Int
    var bestStreak: Int
    var lastPlayedDate: Date?
    var totalCoinsEarned: Int
    var totalXPEarned: Int
    var gameLevel: Int

    init(highScore: Int = 0, gamesPlayed: Int = 0, wins: Int = 0, personalBest: String? = nil,
         currentStreak: Int = 0, bestStreak: Int = 0, lastPlayedDate: Date? = nil,
         totalCoinsEarned: Int = 0, totalXPEarned: Int = 0, gameLevel: Int = 1) {
        self.highScore = highScore
        self.gamesPlayed = gamesPlayed
        self.wins = wins
        self.personalBest = personalBest
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastPlayedDate = lastPlayedDate
        self.totalCoinsEarned = totalCoinsEarned
        self.totalXPEarned = totalXPEarned
        self.gameLevel = gameLevel
    }
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
    var dailyStreak: Int
    var bestDailyStreak: Int
    var lastDailyDate: String?
    var totalCoinsEarned: Int
    var totalGemsEarned: Int
    var dailyBonusCollected: Bool
    var dailyBonusDate: String?
    var favoriteGameId: String?
    var achievements: [String]

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
            perGameStats: [:],
            dailyStreak: 0,
            bestDailyStreak: 0,
            lastDailyDate: nil,
            totalCoinsEarned: 500,
            totalGemsEarned: 0,
            dailyBonusCollected: false,
            dailyBonusDate: nil,
            favoriteGameId: nil,
            achievements: []
        )
    }

    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    mutating func recordGamePlayed(identifier: String, won: Bool, score: Int) {
        gamesPlayed += 1
        if won { totalWins += 1 }
        var stat = perGameStats[identifier] ?? GameStat()
        stat.gamesPlayed += 1
        if won {
            stat.wins += 1
            stat.currentStreak += 1
            stat.bestStreak = max(stat.bestStreak, stat.currentStreak)
        } else {
            stat.currentStreak = 0
        }
        if score > stat.highScore { stat.highScore = score }
        stat.lastPlayedDate = Date()
        perGameStats[identifier] = stat

        updateDailyStreak()
        updateFavoriteGame()
    }

    mutating func updateDailyStreak() {
        let today = Self.dateFormatter.string(from: Date())
        if let lastDate = lastDailyDate {
            if lastDate == today { return }
            let cal = Calendar.current
            if let last = Self.dateFormatter.date(from: lastDate),
               let daysBetween = cal.dateComponents([.day], from: last, to: Date()).day {
                if daysBetween == 1 {
                    dailyStreak += 1
                } else {
                    dailyStreak = 1
                }
            } else {
                dailyStreak = 1
            }
        } else {
            dailyStreak = 1
        }
        bestDailyStreak = max(bestDailyStreak, dailyStreak)
        lastDailyDate = today
    }

    mutating func collectDailyBonus() -> (coins: Int, gems: Int) {
        let today = Self.dateFormatter.string(from: Date())
        if dailyBonusDate == today && dailyBonusCollected { return (0, 0) }
        dailyBonusCollected = true
        dailyBonusDate = today
        let streakBonus = min(dailyStreak, 7)
        let bonusCoins = 50 + (streakBonus * 25)
        let bonusGems = streakBonus >= 7 ? 1 : 0
        return (bonusCoins, bonusGems)
    }

    var isDailyBonusAvailable: Bool {
        let today = Self.dateFormatter.string(from: Date())
        return dailyBonusDate != today || !dailyBonusCollected
    }

    var winRate: Double {
        gamesPlayed > 0 ? Double(totalWins) / Double(gamesPlayed) * 100 : 0
    }

    mutating func addAchievement(_ id: String) {
        guard !achievements.contains(id) else { return }
        achievements.append(id)
    }

    func gameLevel(for identifier: String) -> Int {
        perGameStats[identifier]?.gameLevel ?? 1
    }

    mutating func levelUpGame(_ identifier: String) {
        var stat = perGameStats[identifier] ?? GameStat()
        stat.gameLevel += 1
        perGameStats[identifier] = stat
    }

    private mutating func updateFavoriteGame() {
        favoriteGameId = perGameStats.max(by: { $0.value.gamesPlayed < $1.value.gamesPlayed })?.key
    }
}
