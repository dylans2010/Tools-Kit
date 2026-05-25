import SwiftUI

struct SudokuMasterView: View {
    @StateObject private var logic = SudokuMasterLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GamingDesignTokens.background.ignoresSafeArea()
            switch logic.phase {
            case .lobby: lobbyView
            case .playing: gameView
            case .results: resultsView
            }
            if xpEngine.didLevelUp { LevelUpPopupView(level: xpEngine.newLevel, bonusCoins: xpEngine.bonusCoinsAwarded) { xpEngine.clearLevelUp() } }
        }
        .navigationTitle("Sudoku Master").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.3x3.topleft.filled").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Sudoku Master").font(.title.bold()).foregroundColor(.white)
            Text("Classic Sudoku puzzles.\nHints cost 25 coins each.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            VStack(spacing: 12) {
                ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                    Button(label) { logic.startGame(difficulty: idx) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                }
            }.padding(.horizontal, 32)
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
                Spacer()
                Button("Hint (25c)") { logic.useHint() }.font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
            }.padding(.horizontal)

            sudokuGrid
            numberPad
        }
    }

    private var sudokuGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { c in
                        let isSelected = logic.selectedCell?.row == r && logic.selectedCell?.col == c
                        let val = logic.playerGrid.count > r && logic.playerGrid[r].count > c ? logic.playerGrid[r][c] : 0
                        let isOrig = logic.isOriginal.count > r && logic.isOriginal[r].count > c ? logic.isOriginal[r][c] : false
                        ZStack {
                            Rectangle().fill(isSelected ? GamingDesignTokens.accentNeon.opacity(0.2) : GamingDesignTokens.cardSurface)
                                .border(Color.white.opacity(0.15), width: 0.5)
                            if val != 0 {
                                Text("\(val)").font(.system(size: 16, weight: isOrig ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(isOrig ? .white : GamingDesignTokens.accentNeon)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .overlay(
                            Rectangle().stroke(Color.white.opacity(c % 3 == 2 && c != 8 ? 0.5 : 0), lineWidth: c % 3 == 2 && c != 8 ? 1.5 : 0).offset(x: 18)
                        )
                        .onTapGesture { logic.selectedCell = (r, c) }
                    }
                }
                .overlay(
                    Rectangle().stroke(Color.white.opacity(r % 3 == 2 && r != 8 ? 0.5 : 0), lineWidth: r % 3 == 2 && r != 8 ? 1.5 : 0).offset(y: 18)
                )
            }
        }.padding(.horizontal)
    }

    private var numberPad: some View {
        HStack(spacing: 4) {
            ForEach(1...9, id: \.self) { n in
                Button("\(n)") { logic.placeNumber(n) }.font(.headline).foregroundColor(.white)
                    .frame(width: 34, height: 40).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6))
            }
            Button("C") { logic.clearCell() }.font(.headline).foregroundColor(GamingDesignTokens.dangerRed)
                .frame(width: 34, height: 40).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6))
        }.padding(.horizontal)
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Puzzle Complete!").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score) | Hints: \(logic.hintsUsed)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }
}
