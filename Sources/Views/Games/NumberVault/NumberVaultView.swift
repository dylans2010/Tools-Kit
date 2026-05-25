import SwiftUI

struct NumberVaultView: View {
    @StateObject private var logic = NumberVaultLogic()
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
        .navigationTitle("Number Vault").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "number.square.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Number Vault").font(.title.bold()).foregroundColor(.white)
                Text("Memorize the grid of numbers,\nthen reproduce them from memory.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                let stats = ledger.gameStats(for: logic.gameIdentifier)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("Best: \(stats.highScore)").font(.caption2).foregroundColor(GamingDesignTokens.accentGold)
                    }
                }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["3×3 Easy", "4×4 Medium", "5×5 Hard"].enumerated()), id: \.offset) { idx, label in
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
        VStack(spacing: 16) {
            HStack {
                Text(logic.isMemorizing ? "Memorize!" : "Reproduce the numbers").font(.headline).foregroundColor(logic.isMemorizing ? GamingDesignTokens.accentGold : GamingDesignTokens.accentNeon)
                Spacer()
                if logic.round > 0 { Text("Round \(logic.round)").font(.caption2).foregroundColor(.white.opacity(0.6)) }
                if logic.perfectStreak > 0 { Text("🔥\(logic.perfectStreak)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
            }.padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: logic.gridSize), spacing: 8) {
                ForEach(0..<logic.gridSize, id: \.self) { r in
                    ForEach(0..<logic.gridSize, id: \.self) { c in
                        cellView(row: r, col: c)
                    }
                }
            }.padding(.horizontal, 24)
            if !logic.isMemorizing {
                numberPad
                Button("Submit") { logic.submitGrid() }.font(.headline).foregroundColor(.black).padding(.horizontal, 40).padding(.vertical, 12).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isSelected = logic.selectedCell?.row == row && logic.selectedCell?.col == col
        return ZStack {
            RoundedRectangle(cornerRadius: 8).fill(isSelected ? GamingDesignTokens.accentNeon.opacity(0.2) : GamingDesignTokens.cardSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? GamingDesignTokens.accentNeon : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1))
            if logic.isMemorizing {
                Text("\(logic.grid[row][col])").font(.title.bold().monospacedDigit()).foregroundColor(.white)
            } else {
                Text(logic.playerGrid[row][col].map { "\($0)" } ?? "").font(.title.bold().monospacedDigit()).foregroundColor(GamingDesignTokens.accentNeon)
            }
        }.frame(height: 60).onTapGesture { logic.selectedCell = (row, col) }
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
            ForEach(1...9, id: \.self) { n in
                Button("\(n)") {
                    if let sel = logic.selectedCell { logic.inputNumber(n, row: sel.row, col: sel.col) }
                }.font(.headline).foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 8))
            }
        }.padding(.horizontal, 24)
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
                Text("Results").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Correct Cells", "\(logic.correctCount)/\(logic.gridSize * logic.gridSize)")
                    statRow("Perfect Rounds", "\(logic.perfectStreak)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
