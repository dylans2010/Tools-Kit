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
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "square.grid.3x3.topleft.filled").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Sudoku Master").font(.title.bold()).foregroundColor(.white)
                Text("Classic Sudoku puzzles.\nFewer hints used = higher score!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                let stats = ledger.gameStats(for: logic.gameIdentifier)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("Wins: \(stats.wins)").font(.caption2).foregroundColor(GamingDesignTokens.successGreen)
                    }
                }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button(label) { logic.startGame(difficulty: idx) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(idx == 0 ? GamingDesignTokens.accentNeon : (idx == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed), in: Capsule())
                    }
                }.padding(.horizontal, 32)

                if ledger.canClaimDailyBonus(for: logic.gameIdentifier) {
                    Button { ledger.claimDailyBonus(for: logic.gameIdentifier) } label: {
                        Label("Claim Daily Bonus", systemImage: "gift.fill").font(.subheadline.bold()).foregroundColor(.black)
                            .padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    }
                }
            }.padding()
        }
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
                Spacer()
                Text("Mistakes: \(logic.mistakes)/\(logic.maxMistakes)").font(.caption2).foregroundColor(logic.mistakes >= logic.maxMistakes - 1 ? GamingDesignTokens.dangerRed : .white.opacity(0.6))
                Spacer()
                if logic.hintsRemaining > 0 {
                    Button("Hint (\(logic.hintsRemaining))") { logic.useHint() }.font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                }
            }.padding(.horizontal)
            if logic.elapsedTime > 0 { Text(String(format: "⏱ %.0fs", logic.elapsedTime)).font(.caption2).foregroundColor(.white.opacity(0.5)) }
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
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.won ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64)).foregroundColor(logic.won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.won ? "Puzzle Solved!" : "Too Many Mistakes").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Time", String(format: "%.0fs", logic.elapsedTime))
                    statRow("Hints Used", "\(logic.hintsUsed)")
                    statRow("Mistakes", "\(logic.mistakes)")
                    statRow("Difficulty", logic.difficulty == 0 ? "Easy" : (logic.difficulty == 1 ? "Medium" : "Hard"))
                    statRow("Streak Multiplier", String(format: "%.1fx", logic.streakMultiplier))
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)
                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold).padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
