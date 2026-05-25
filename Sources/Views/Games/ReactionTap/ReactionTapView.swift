import SwiftUI

struct ReactionTapView: View {
    @StateObject private var logic = ReactionTapLogic()
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
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
        .navigationTitle("Reaction Tap").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Reaction Tap").font(.title.bold()).foregroundColor(.white)
                Text("Wait for green, then tap as fast as you can!\nPerfect taps under 200ms earn bonuses.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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

                Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()

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
        VStack(spacing: 0) {
            HStack {
                Text("Round \(logic.round)/\(logic.totalRounds)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.consecutiveFast > 0 { Text("🔥\(logic.consecutiveFast)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.perfectTaps > 0 { Text("Perfect: \(logic.perfectTaps)").font(.caption2).foregroundColor(GamingDesignTokens.accentPurple) }
            }.padding(.horizontal).padding(.top, 8)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(logic.tooEarly ? GamingDesignTokens.dangerRed : (logic.isGreen ? GamingDesignTokens.successGreen : GamingDesignTokens.cardSurface))
                    .frame(height: 300).padding(.horizontal, 32)
                if logic.tooEarly { Text("Too Early!").font(.title.bold()).foregroundColor(.white) }
                else if logic.isGreen { Text("TAP NOW!").font(.title.bold()).foregroundColor(.white) }
                else if logic.waiting { Text("Wait...").font(.title2).foregroundColor(.white.opacity(0.5)) }
                if let rt = logic.reactionTime { Text("\(Int(rt)) ms").font(.system(size: 48, weight: .black, design: .monospaced)).foregroundColor(.white) }
            }.onTapGesture { logic.tap() }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Results").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Best Time", "\(Int(logic.bestTime)) ms")
                    statRow("Average Time", "\(Int(logic.averageTime)) ms")
                    statRow("Perfect Taps", "\(logic.perfectTaps)")
                    statRow("Consecutive Fast", "\(logic.bestConsecutiveFast)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.bestTime < 300, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
