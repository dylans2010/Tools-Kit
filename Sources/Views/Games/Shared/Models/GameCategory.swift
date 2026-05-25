import SwiftUI

enum GameCategory: String, Codable, CaseIterable {
    case warAndBattle = "War & Battle"
    case casinoAndGambling = "Gambling & Casino"
    case memoryAndBrain = "Memory & Brain"
    case puzzlesAndLogic = "Puzzles & Logic"
    case arcadeAndReflex = "Arcade & Reflex"
    case boardAndClassic = "Board & Classic"
    case spinAndLuck = "Spin & Luck"

    var icon: String {
        switch self {
        case .warAndBattle: return "shield.fill"
        case .casinoAndGambling: return "suit.spade.fill"
        case .memoryAndBrain: return "brain.head.profile"
        case .puzzlesAndLogic: return "puzzlepiece.fill"
        case .arcadeAndReflex: return "gamecontroller.fill"
        case .boardAndClassic: return "checkerboard.rectangle"
        case .spinAndLuck: return "star.circle.fill"
        }
    }
}

protocol GamesRewardable {
    var gameIdentifier: String { get }
    var baseXPReward: Int { get }
    var winXPBonus: Int { get }
    var baseCoinReward: Int { get }
    var winCoinBonus: Int { get }
    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward
}

struct GameReward {
    let xp: Int
    let coins: Int
    let gems: Int
    let badgeUnlocked: String?
}
