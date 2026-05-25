import SwiftUI

struct SpinWheelPrizeView: View {
    @StateObject private var logic = SpinWheelPrizeLogic()
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
        .navigationTitle("Spin Wheel").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Spin Wheel Prize").font(.title.bold()).foregroundColor(.white)
                Text("Spin the wheel to win coins!\n25 coins per spin. Free spins from streaks!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
        VStack(spacing: 16) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            ZStack {
                Circle().fill(GamingDesignTokens.cardSurface).frame(width: 250, height: 250)
                ForEach(Array(logic.slices.enumerated()), id: \.element.id) { idx, slice in
                    let angle = Double(idx) * (360.0 / Double(logic.slices.count))
                    Text(slice.label).font(.caption.bold()).foregroundColor(.white)
                        .offset(y: -90).rotationEffect(.degrees(angle))
                }
            }.rotationEffect(.degrees(logic.rotation))
            .animation(.easeOut(duration: 3.0), value: logic.rotation)

            Image(systemName: "arrowtriangle.down.fill").font(.title).foregroundColor(GamingDesignTokens.dangerRed)

            HStack(spacing: 12) {
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.freeSpinsAvailable > 0 { Text("Free: \(logic.freeSpinsAvailable)").font(.caption.bold()).foregroundColor(GamingDesignTokens.successGreen) }
            }

            if let result = logic.resultSlice {
                Text(result.prize > 0 ? "+\(result.prize) coins!" : "No prize").font(.title2.bold()).foregroundColor(result.prize > 0 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            }
            Button(logic.isSpinning ? "Spinning..." : (logic.freeSpinsAvailable > 0 ? "FREE SPIN" : "Spin (25c)")) { logic.spin() }
                .font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 50).padding(.vertical, 14)
                .background(logic.isSpinning ? Color.gray : (logic.freeSpinsAvailable > 0 ? GamingDesignTokens.successGreen : GamingDesignTokens.accentGold), in: Capsule()).disabled(logic.isSpinning)
            Button("End") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Session Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Spins", "\(logic.spins)")
                    statRow("Total Won", "\(logic.totalWon)")
                    statRow("Biggest Win", "\(logic.biggestWin)")
                    statRow("Best Streak", "\(logic.bestConsecutiveWins)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.totalWon > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
