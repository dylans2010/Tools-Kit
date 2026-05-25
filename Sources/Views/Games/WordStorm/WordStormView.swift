import SwiftUI

struct WordStormView: View {
    @StateObject private var logic = WordStormLogic()
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
        .navigationTitle("Word Storm").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "textformat.abc").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
                Text("Word Storm").font(.title.bold()).foregroundColor(.white)
                Text("Unscramble words before time runs out!\nHarder difficulty = longer words + less time.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
        VStack(spacing: 16) {
            HStack {
                Text(String(format: "%.1f", logic.timeRemaining) + "s").font(GamingDesignTokens.fontMono).foregroundColor(logic.timeRemaining < 10 ? GamingDesignTokens.dangerRed : .white)
                Spacer()
                if logic.consecutiveSolves > 0 { Text("🔥\(logic.consecutiveSolves)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            Text("Solved: \(logic.solvedWords.count)/\(logic.wordsToSolve)").font(.caption).foregroundColor(.white.opacity(0.6))
            if logic.hintsAvailable > 0 {
                Button("Hint (\(logic.hintsAvailable))") { logic.useHint() }.font(.caption2.bold()).foregroundColor(.white).padding(4).background(GamingDesignTokens.accentPurple, in: Capsule())
            }

            HStack(spacing: 8) {
                ForEach(Array(logic.scrambledLetters.enumerated()), id: \.offset) { idx, letter in
                    Button { logic.tapLetter(idx) } label: {
                        Text(String(letter).uppercased()).font(.title.bold()).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(GamingDesignTokens.accentPurple, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Text(logic.playerInput.uppercased()).font(.title2.bold().monospaced()).foregroundColor(GamingDesignTokens.accentNeon).frame(height: 40)

            HStack(spacing: 16) {
                Button("Clear") { logic.clearInput() }.foregroundColor(GamingDesignTokens.dangerRed)
                Button("Submit") { logic.submitAnswer() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "textformat.abc").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
                Text("Time's Up!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Words Solved", "\(logic.solvedWords.count)/\(logic.wordsToSolve)")
                    statRow("Best Streak", "\(logic.bestConsecutiveSolves)")
                    statRow("Hints Used", "\(logic.hintsUsed)")
                    statRow("Score", "\(logic.score)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.solvedWords.count > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
