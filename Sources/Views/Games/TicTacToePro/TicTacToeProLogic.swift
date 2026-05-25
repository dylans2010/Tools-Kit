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
    @Published var losses = 0
    @Published var draws = 0
    @Published var games = 0
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0
    @Published var totalRounds = 5
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0

    enum GamePhase { case lobby, playing, results }

    private let winPatterns: [[Int]] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]

    var difficultyName: String {
        switch difficulty { case 0: return "Easy"; case 1: return "Medium"; default: return "Hard" }
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        board = Array(repeating: "", count: 9); currentPlayer = "X"; result = ""; gameOver = false
        games = 0; wins = 0; losses = 0; draws = 0; score = 0; consecutiveWins = 0; bestConsecutiveWins = 0
        totalRounds = 5 + difficulty * 2
        phase = .playing
    }

    func makeMove(_ index: Int) {
        guard board[index].isEmpty, !gameOver, currentPlayer == "X" else { return }
        board[index] = "X"
        if checkWin("X") {
            result = "You Win!"
            let movesMade = board.filter({ !$0.isEmpty }).count
            let speedBonus = max(0, (9 - movesMade) * 10)
            score += 50 + speedBonus + (difficulty * 25)
            wins += 1; consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            gameOver = true; games += 1; return
        }
        if board.allSatisfy({ !$0.isEmpty }) { result = "Draw"; draws += 1; games += 1; score += 10; gameOver = true; return }
        currentPlayer = "O"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        switch difficulty {
        case 0: aiMoveEasy()
        case 1: aiMoveMedium()
        default: aiMoveHard()
        }
        if checkWin("O") { result = "CPU Wins"; losses += 1; consecutiveWins = 0; streakMultiplier = max(1.0, streakMultiplier - 0.1); gameOver = true; games += 1; return }
        if board.allSatisfy({ !$0.isEmpty }) { result = "Draw"; draws += 1; games += 1; score += 10; gameOver = true; return }
        currentPlayer = "X"
    }

    private func aiMoveEasy() {
        if let randomMove = board.indices.filter({ board[$0].isEmpty }).randomElement() { board[randomMove] = "O" }
    }

    private func aiMoveMedium() {
        if let winMove = findMove("O") { board[winMove] = "O" }
        else if let blockMove = findMove("X") { board[blockMove] = "O" }
        else if board[4].isEmpty { board[4] = "O" }
        else if let randomMove = board.indices.filter({ board[$0].isEmpty }).randomElement() { board[randomMove] = "O" }
    }

    private func aiMoveHard() {
        if let winMove = findMove("O") { board[winMove] = "O" }
        else if let blockMove = findMove("X") { board[blockMove] = "O" }
        else if board[4].isEmpty { board[4] = "O" }
        else if let corner = [0, 2, 6, 8].first(where: { board[$0].isEmpty }) { board[corner] = "O" }
        else if let forkMove = findForkMove("O") { board[forkMove] = "O" }
        else if let blockFork = findForkMove("X") { board[blockFork] = "O" }
        else if let side = board.indices.filter({ board[$0].isEmpty }).randomElement() { board[side] = "O" }
    }

    private func findForkMove(_ player: String) -> Int? {
        for i in board.indices where board[i].isEmpty {
            board[i] = player
            var threatCount = 0
            for pattern in winPatterns {
                let marks = pattern.map { board[$0] }
                if marks.filter({ $0 == player }).count == 2 && marks.contains("") { threatCount += 1 }
            }
            board[i] = ""
            if threatCount >= 2 { return i }
        }
        return nil
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
        let diffBonus = difficulty * 15
        var badge: String?
        if wins >= totalRounds { badge = "Tic Tac Dominator" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Tic Tac Streak" }
        if wins > 0 && losses == 0 { badge = badge ?? "Undefeated" }
        if difficulty >= 2 && wins >= 3 { badge = badge ?? "Tic Tac Master" }
        let gems = wins >= totalRounds && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }
}
