import SwiftUI

struct PokerNightsView: View {
    @StateObject private var logic = PokerNightsLogic()
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss
    @State private var raiseAmount = 40

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
        .navigationTitle("Poker Nights").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "suit.diamond.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Poker Nights").font(.title.bold()).foregroundColor(.white)
                Text("5-card draw poker vs AI opponents.\nBet, bluff, and win the pot!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Table") { logic.startGame(difficulty: idx) }
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
        VStack(spacing: 12) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack {
                Text("Round \(logic.currentRound)/\(logic.totalRounds) | Pot: \(logic.pot)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold)
                Spacer()
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
            }.padding(.horizontal)

            ForEach(logic.players.filter { !$0.isHuman }) { p in
                HStack {
                    Text(p.name).font(.caption.bold()).foregroundColor(p.folded ? .gray : GamingDesignTokens.dangerRed)
                    Spacer()
                    if logic.showdown && !p.folded {
                        HStack { ForEach(p.hand) { c in Text(c.display).font(.caption) } }
                    } else { Text(p.folded ? "Folded" : "\(p.hand.count) cards").font(.caption).foregroundColor(.white.opacity(0.5)) }
                }.padding(.horizontal)
            }
            Divider().background(Color.white.opacity(0.2))
            if let human = logic.players.first(where: { $0.isHuman }) {
                Text("Your Hand").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                HStack { ForEach(human.hand) { c in Text(c.display).font(.title2).padding(4).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6)) } }
                let eval = PokerHandEvaluator.evaluate(human.hand)
                Text(eval.rank.name).font(.caption).foregroundColor(GamingDesignTokens.accentPurple)
            }
            if !logic.roundResult.isEmpty {
                Text(logic.roundResult).font(.headline).foregroundColor(GamingDesignTokens.accentGold).padding()
                if !logic.gameOver { Button("Next Round") { logic.nextRound() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule()) }
            } else if !(logic.players.first(where: { $0.isHuman })?.folded ?? true) {
                HStack(spacing: 12) {
                    Button("Call") { logic.call() }.font(.subheadline.bold()).foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 8).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Raise \(raiseAmount)") { logic.raise(amount: raiseAmount) }.font(.subheadline.bold()).foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 8).background(GamingDesignTokens.accentGold, in: Capsule())
                    Button("Bluff") { logic.bluff(amount: raiseAmount) }.font(.subheadline.bold()).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 8).background(GamingDesignTokens.accentPurple, in: Capsule())
                    Button("Fold") { logic.fold() }.font(.subheadline.bold()).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 8).background(GamingDesignTokens.dangerRed, in: Capsule())
                }
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "suit.diamond.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Game Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Rounds Won", "\(logic.roundWins)/\(logic.totalRounds)")
                    statRow("Best Streak", "\(logic.bestConsecutiveWins)")
                    statRow("Biggest Pot", "\(logic.biggestPot)")
                    statRow("Bluffs", "\(logic.bluffsAttempted)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.roundWins > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
