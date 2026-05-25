import Foundation

class ChessLiteLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "chess_lite"
    let baseXPReward = 150
    let winXPBonus = 100
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: 0, gems: won ? 1 : 0, badgeUnlocked: nil)
    }

    func isValidMove(piece: ChessPieceModel, from: (Int, Int), to: (Int, Int), board: [[ChessPieceModel?]]) -> Bool {
        // Simplified move validation
        let dr = abs(to.0 - from.0)
        let dc = abs(to.1 - from.1)
        switch piece.type {
        case .pawn: return dc == 0 && dr == 1
        case .rook: return dr == 0 || dc == 0
        case .bishop: return dr == dc
        case .knight: return (dr == 2 && dc == 1) || (dr == 1 && dc == 2)
        case .queen: return dr == dc || dr == 0 || dc == 0
        case .king: return dr <= 1 && dc <= 1
        }
    }
}
