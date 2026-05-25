import SwiftUI

struct AsteroidDodgeView: View {
    @StateObject private var logic = AsteroidDodgeLogic()
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
        .navigationTitle("Asteroid Dodge").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Asteroid Dodge").font(.title.bold()).foregroundColor(.white)
                Text("Dodge falling asteroids!\nCollect power-ups for shields and slow-mo.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                gameLevelBadge

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button("\(label) Launch") { logic.startGame(difficulty: idx) }
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

    private var gameLevelBadge: some View {
        let stats = ledger.gameStats(for: logic.gameIdentifier)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Best: \(stats.highScore)").font(.caption2).foregroundColor(GamingDesignTokens.accentGold)
            }
        }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))
    }

    private var gameView: some View {
        GeometryReader { geo in
            ZStack {
                Text("\(logic.score)").font(.system(size: 60, weight: .black, design: .monospaced)).foregroundColor(.white.opacity(0.1))

                ForEach(logic.powerUps) { p in
                    Image(systemName: p.type == .shield ? "shield.fill" : (p.type == .slowmo ? "tortoise.fill" : (p.type == .coin ? "dollarsign.circle.fill" : "magnet")))
                        .font(.system(size: 20)).foregroundColor(GamingDesignTokens.accentGold)
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                }

                ForEach(logic.asteroids) { a in
                    Circle().fill(Color.gray.opacity(0.7)).frame(width: a.size, height: a.size)
                        .position(x: a.x * geo.size.width, y: a.y * geo.size.height)
                }

                Image(systemName: "arrowtriangle.up.fill").font(.system(size: 30))
                    .foregroundColor(logic.shieldActive ? GamingDesignTokens.accentGold : GamingDesignTokens.accentNeon)
                    .position(x: logic.playerX * geo.size.width, y: geo.size.height * 0.85)
            }
            .gesture(DragGesture().onChanged { v in logic.movePlayer(to: v.location.x / geo.size.width) })
            .overlay(alignment: .top) {
                HStack {
                    Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
                    Spacer()
                    if logic.shieldActive { Image(systemName: "shield.fill").foregroundColor(GamingDesignTokens.accentGold) }
                    if logic.slowmoActive { Image(systemName: "tortoise.fill").foregroundColor(GamingDesignTokens.accentPurple) }
                    if logic.streakMultiplier > 1.0 {
                        Text("×\(String(format: "%.1f", logic.streakMultiplier))").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple)
                    }
                    Text("Near: \(logic.nearMisses)").font(.caption2).foregroundColor(.white.opacity(0.6))
                }.padding(8)
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Crash!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Near Misses", "\(logic.nearMisses)")
                    statRow("Coins Collected", "\(logic.coinsCollected)")
                    statRow("Survival Time", String(format: "%.0fs", logic.survivalTime))
                    statRow("Streak Multiplier", String(format: "%.1fx", logic.streakMultiplier))
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)
                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold)
                        .padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 300, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
