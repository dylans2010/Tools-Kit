import SwiftUI

struct BubblePopFrenzyView: View {
    @StateObject private var logic = BubblePopFrenzyLogic()
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
        .navigationTitle("Bubble Pop Frenzy").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.hexagongrid.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Bubble Pop Frenzy").font(.title.bold()).foregroundColor(.white)
                Text("Pop bubbles before time runs out!\nGolden bubbles = bonus time & coins.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Pop") { logic.startGame(difficulty: idx) }
                            .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
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
        GeometryReader { geo in
            ZStack {
                ForEach(logic.bubbles) { b in
                    Circle()
                        .fill(b.isBomb ? GamingDesignTokens.dangerRed : (b.isGolden ? GamingDesignTokens.accentGold : Color.blue))
                        .frame(width: b.size, height: b.size)
                        .overlay { if b.isGolden { Image(systemName: "star.fill").font(.caption).foregroundColor(.white) }
                            else if b.isBomb { Image(systemName: "bolt.fill").font(.caption).foregroundColor(.white) } }
                        .position(x: b.x * geo.size.width, y: b.y * geo.size.height)
                        .onTapGesture { logic.popBubble(b.id) }
                }
            }
            .overlay(alignment: .top) {
                HStack {
                    Text(String(format: "⏱ %.0f", logic.timeRemaining)).font(.caption.bold()).foregroundColor(logic.timeRemaining < 10 ? GamingDesignTokens.dangerRed : .white)
                    Spacer()
                    if logic.combo > 1 { Text("Combo ×\(logic.combo)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple) }
                    Spacer()
                    Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
                    if logic.bonusTimeEarned > 0 { Text("+\(Int(logic.bonusTimeEarned))s").font(.caption2).foregroundColor(GamingDesignTokens.successGreen) }
                }.padding(8)
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.hexagongrid.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Time's Up!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Bubbles Popped", "\(logic.totalPopped)")
                    statRow("Golden Bubbles", "\(logic.goldenPopped)")
                    statRow("Best Combo", "\(logic.bestCombo)")
                    statRow("Bonus Time", "+\(Int(logic.bonusTimeEarned))s")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 200, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
