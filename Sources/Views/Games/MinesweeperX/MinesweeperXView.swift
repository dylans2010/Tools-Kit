import SwiftUI

struct MinesweeperXView: View {
    @StateObject private var logic = MinesweeperXLogic()
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
        .navigationTitle("Minesweeper X").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.grid.cross.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Minesweeper X").font(.title.bold()).foregroundColor(.white)
                Text("Classic Minesweeper. First tap is always safe.\nUse hints wisely!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                    ForEach(Array(["9×9 Easy", "16×16 Medium", "30×16 Hard"].enumerated()), id: \.offset) { idx, label in
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
                Button(logic.flagMode ? "🚩 Flag" : "👆 Tap") { logic.flagMode.toggle() }.font(.caption.bold()).foregroundColor(.white).padding(6).background(logic.flagMode ? GamingDesignTokens.dangerRed : GamingDesignTokens.accentNeon, in: Capsule())
                Spacer()
                if logic.hintsUsed < logic.maxHints {
                    Button("Hint (\(logic.maxHints - logic.hintsUsed))") { logic.useHint() }.font(.caption2.bold()).foregroundColor(.white).padding(4).background(GamingDesignTokens.accentPurple, in: Capsule())
                }
                Spacer()
                Text(String(format: "⏱ %.0f", logic.elapsedTime)).font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 1) {
                    ForEach(0..<logic.rows, id: \.self) { r in
                        HStack(spacing: 1) {
                            ForEach(0..<logic.cols, id: \.self) { c in
                                mineCellView(r, c)
                            }
                        }
                    }
                }.padding(4)
            }
        }
    }

    private func mineCellView(_ r: Int, _ c: Int) -> some View {
        let cell = r < logic.grid.count && c < logic.grid[r].count ? logic.grid[r][c] : MineCell()
        let size: CGFloat = logic.rows <= 9 ? 32 : 22
        return ZStack {
            Rectangle().fill(cell.isRevealed ? (cell.isMine ? GamingDesignTokens.dangerRed.opacity(0.3) : Color.white.opacity(0.05)) : GamingDesignTokens.cardSurface)
            if cell.isFlagged && !cell.isRevealed { Text("🚩").font(.system(size: size * 0.5)) }
            else if cell.isRevealed && cell.isMine { Text("💣").font(.system(size: size * 0.5)) }
            else if cell.isRevealed && cell.adjacentMines > 0 {
                Text("\(cell.adjacentMines)").font(.system(size: size * 0.5, weight: .bold, design: .monospaced))
                    .foregroundColor(cell.adjacentMines <= 2 ? GamingDesignTokens.accentNeon : (cell.adjacentMines <= 4 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed))
            }
        }.frame(width: size, height: size).border(Color.white.opacity(0.08), width: 0.5)
        .onTapGesture { logic.tap(row: r, col: c) }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.won ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64)).foregroundColor(logic.won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.won ? "You Win!" : "Boom!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Time", String(format: "%.0fs", logic.elapsedTime))
                    statRow("Hints Used", "\(logic.hintsUsed)/\(logic.maxHints)")
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
