import SwiftUI

struct SnakeLadderClassicView: View {
    @StateObject private var logic = SnakeLadderClassicLogic()
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
        .navigationTitle("Snakes & Ladders").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
                Text("Snakes & Ladders").font(.title.bold()).foregroundColor(.white)
                Text("Classic board game vs CPU.\nUse power-ups for best of 2 dice rolls!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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

                Button("Start Game") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()

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
            ForEach(logic.players) { p in
                HStack {
                    Circle().fill(p.isHuman ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed).frame(width: 12, height: 12)
                    Text("\(p.name): \(p.position)").foregroundColor(.white).font(.headline)
                    if logic.currentPlayerIndex < logic.players.count && logic.players[logic.currentPlayerIndex].id == p.id { Text("← turn").font(.caption).foregroundColor(GamingDesignTokens.accentGold) }
                }
            }
            if logic.lastDice > 0 { Text("🎲 \(logic.lastDice)").font(.system(size: 48, weight: .black)).foregroundColor(.white) }
            if !logic.message.isEmpty { Text(logic.message).font(.subheadline).foregroundColor(GamingDesignTokens.accentNeon).multilineTextAlignment(.center).padding(.horizontal) }
            if logic.powerUpsAvailable > 0 { Text("Power-ups: \(logic.powerUpsAvailable)").font(.caption2).foregroundColor(GamingDesignTokens.accentPurple) }
            if !logic.gameOver && logic.currentPlayerIndex < logic.players.count && logic.players[logic.currentPlayerIndex].isHuman {
                HStack(spacing: 12) {
                    Button("Roll Dice") { logic.rollDice() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 40).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule())
                    if logic.powerUpsAvailable > 0 {
                        Button("Power Roll (25)") { logic.usePowerUp() }.font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10).background(GamingDesignTokens.accentPurple, in: Capsule())
                    }
                }
            }
            Spacer()
        }.padding()
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        let won = logic.winner?.isHuman == true
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(won ? "You Win!" : "CPU Wins!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Total Moves", "\(logic.totalMoves)")
                    statRow("Ladders Hit", "\(logic.laddersHit)")
                    statRow("Snakes Hit", "\(logic.snakesHit)")
                    statRow("Power-ups Used", "\(logic.powerUpsUsed)")
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
