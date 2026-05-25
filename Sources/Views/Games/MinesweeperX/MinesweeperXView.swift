import SwiftUI

struct MinesweeperXView: View {
    @StateObject private var logic = MinesweeperXLogic()
    @State private var gameState: GameState = .lobby
    @State private var grid: [[Cell]] = []
    @State private var revealedCount = 0

    struct Cell: Identifiable {
        let id = UUID()
        var isMine: Bool
        var isRevealed = false
        var neighborMines = 0
    }

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Minesweeper X", gameID: logic.gameIdentifier) { start() }
            case .playing:
                VStack {
                    Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                        ForEach(0..<9) { r in
                            GridRow {
                                ForEach(0..<9) { c in
                                    cellView(r, c)
                                }
                            }
                        }
                    }
                    .padding()
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: revealedCount >= 71, score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func cellView(_ r: Int, _ c: Int) -> some View {
        let cell = grid[r][c]
        return ZStack {
            Rectangle().fill(cell.isRevealed ? Color.white.opacity(0.1) : Color.gray)
            if cell.isRevealed {
                if cell.isMine { Image(systemName: "burst.fill").foregroundColor(.red) }
                else if cell.neighborMines > 0 { Text("\(cell.neighborMines)").foregroundColor(.white) }
            }
        }
        .frame(width: 35, height: 35)
        .onTapGesture { reveal(r, c) }
    }

    private func start() {
        grid = (0..<9).map { _ in (0..<9).map { _ in Cell(isMine: Double.random(in: 0...1) < 0.15) } }
        for r in 0..<9 {
            for c in 0..<9 {
                if !grid[r][c].isMine {
                    grid[r][c].neighborMines = countNeighbors(r, c)
                }
            }
        }
        revealedCount = 0
        gameState = .playing
    }

    private func countNeighbors(_ r: Int, _ c: Int) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = r + dr, nc = c + dc
                if nr >= 0, nr < 9, nc >= 0, nc < 9, grid[nr][nc].isMine { count += 1 }
            }
        }
        return count
    }

    private func reveal(_ r: Int, _ c: Int) {
        guard !grid[r][c].isRevealed else { return }
        grid[r][c].isRevealed = true
        revealedCount += 1
        if grid[r][c].isMine { gameState = .results }
        else if revealedCount >= 81 - grid.flatMap({$0}).filter({$0.isMine}).count { gameState = .results }
    }
}
