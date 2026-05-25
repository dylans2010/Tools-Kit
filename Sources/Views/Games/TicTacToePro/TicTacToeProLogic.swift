import Foundation

final class TicTacToeProLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tic_tac_toe_pro"
    let baseXPReward = 30
    let winXPBonus = 40
    let baseCoinReward = 15
    let winCoinBonus = 10

    @Published var board: [String] = Array(repeating: "", count: 9)
    @Published var currentPlayer = "X"
    @Published var result = ""
    @Published var gameOver = false
    @Published var wins = 0
    @Published var games = 0
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    enum GamePhase { case lobby, playing, results }

    private let winPatterns: [[Int]] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]

    func startGame() {
        board = Array(repeating: "", count: 9); currentPlayer = "X"; result = ""; gameOver = false
        games = 0; wins = 0; score = 0; phase = .playing
    }

    func makeMove(_ index: Int) {
        guard board[index].isEmpty, !gameOver, currentPlayer == "X" else { return }
        board[index] = "X"
        if checkWin("X") { result = "You Win!"; score += 50; wins += 1; streakMultiplier = min(3.0, streakMultiplier + 0.1); gameOver = true; games += 1; return }
        if board.allSatisfy({ !$0.isEmpty }) { result = "Draw"; games += 1; gameOver = true; return }
        currentPlayer = "O"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        if let winMove = findMove("O") { board[winMove] = "O" }
        else if let blockMove = findMove("X") { board[blockMove] = "O" }
        else if board[4].isEmpty { board[4] = "O" }
        else if let randomMove = board.indices.filter({ board[$0].isEmpty }).randomElement() { board[randomMove] = "O" }
        if checkWin("O") { result = "CPU Wins"; streakMultiplier = 1.0; gameOver = true; games += 1; return }
        if board.allSatisfy({ !$0.isEmpty }) { result = "Draw"; games += 1; gameOver = true; return }
        currentPlayer = "X"
    }

    private func findMove(_ player: String) -> Int? {
        for pattern in winPatterns {
            let marks = pattern.map { board[$0] }
            if marks.filter({ $0 == player }).count == 2 && marks.contains("") {
                return pattern[marks.firstIndex(of: "")!]
            }
        }
        return nil
    }

    private func checkWin(_ player: String) -> Bool {
        winPatterns.contains { $0.allSatisfy { board[$0] == player } }
    }

    func newRound() {
        board = Array(repeating: "", count: 9); currentPlayer = "X"; result = ""; gameOver = false
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let won = wins > 0
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus * wins : 0)
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: wins >= 5 ? "Tic Tac Master" : nil)
    }
}
