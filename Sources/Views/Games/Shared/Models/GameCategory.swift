import Foundation

enum GameCategory: String, CaseIterable, Codable, Identifiable {
    case warBattle = "War & Battle"
    case casinoGambling = "Gambling & Casino"
    case memoryBrain = "Memory & Brain"
    case puzzleLogic = "Puzzles & Logic"
    case arcadeReflex = "Arcade & Reflex"
    case boardClassic = "Board & Classic"
    case spinLuck = "Spin & Luck"

    var id: String { rawValue }

    var label: String { rawValue }

    var filterLabel: String {
        switch self {
        case .warBattle: return "War"
        case .casinoGambling: return "Casino"
        case .memoryBrain: return "Brain"
        case .puzzleLogic: return "Puzzles"
        case .arcadeReflex: return "Arcade"
        case .boardClassic: return "Board"
        case .spinLuck: return "Luck"
        }
    }

    var icon: String {
        switch self {
        case .warBattle: return "shield.fill"
        case .casinoGambling: return "suit.spade.fill"
        case .memoryBrain: return "brain.head.profile"
        case .puzzleLogic: return "puzzlepiece.fill"
        case .arcadeReflex: return "gamecontroller.fill"
        case .boardClassic: return "checkerboard.rectangle"
        case .spinLuck: return "star.circle.fill"
        }
    }
}
