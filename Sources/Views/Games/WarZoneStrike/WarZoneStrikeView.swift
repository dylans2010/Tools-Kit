import SwiftUI

struct WarZoneStrikeView: View {
    @StateObject private var logic = WarZoneStrikeLogic()
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
        .navigationTitle("WarZone Strike").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "scope").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
                Text("WarZone Strike").font(.title.bold()).foregroundColor(.white)
                Text("Tap enemies crossing a 3-lane battlefield.\nHigher difficulty = more enemies + faster.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Mission") { logic.startGame(difficulty: idx) }
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
        VStack(spacing: 8) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack {
                Text("Wave \(logic.currentWave + 1)/\(logic.totalWaves)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.killStreak > 0 { Text("🔥\(logic.killStreak)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                Spacer()
                Text("Lives: \(logic.lives)").font(.caption.bold()).foregroundColor(logic.lives <= 2 ? GamingDesignTokens.dangerRed : .white)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            GeometryReader { geo in
                let laneHeight = geo.size.height / 3
                ZStack {
                    ForEach(0..<3, id: \.self) { lane in
                        Rectangle().fill(Color.white.opacity(lane % 2 == 0 ? 0.03 : 0.06))
                            .frame(height: laneHeight).offset(y: CGFloat(lane) * laneHeight)
                    }
                    ForEach(logic.enemies) { enemy in
                        Circle()
                            .fill(GamingDesignTokens.dangerRed)
                            .frame(width: 36, height: 36)
                            .overlay(Text("\(enemy.health)").font(.caption2.bold()).foregroundColor(.white))
                            .position(x: CGFloat(enemy.position / 10.0) * geo.size.width,
                                      y: CGFloat(enemy.lane) * laneHeight + laneHeight / 2)
                            .onTapGesture { logic.tapEnemy(enemy) }
                    }
                }
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        let won = logic.currentWave >= logic.totalWaves
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: won ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(won ? "Mission Complete!" : "Mission Failed").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Waves Survived", "\(logic.currentWave)")
                    statRow("Enemies Eliminated", "\(logic.totalKills)")
                    statRow("Best Kill Streak", "\(logic.bestKillStreak)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: won, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
