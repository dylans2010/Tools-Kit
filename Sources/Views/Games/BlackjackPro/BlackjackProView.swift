import SwiftUI

struct BlackjackProView: View {
    @StateObject private var logic = BlackjackProLogic()
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
        .navigationTitle("Blackjack Pro").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "suit.spade.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Blackjack Pro").font(.title.bold()).foregroundColor(.white)
                Text("Beat the dealer to 21.\nInsurance, Surrender, Double Down!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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

                Button("Play Blackjack") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()

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
            HStack {
                Text("Dealer: \(logic.dealerTotal)").font(.headline).foregroundColor(.white)
                Spacer()
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.streakMultiplier > 1.0 { Text("×\(String(format: "%.1f", logic.streakMultiplier))").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple) }
            }.padding(.horizontal)
            HStack { ForEach(logic.dealerHand) { c in cardView(c) } }.padding(.horizontal)
            Divider().background(Color.white.opacity(0.2))
            Text("Your Hand: \(logic.playerTotal)").font(.headline).foregroundColor(.white)
            HStack { ForEach(logic.playerHand) { c in cardView(c) } }.padding(.horizontal)
            Text("Bet: \(logic.bet)").font(.caption).foregroundColor(.white.opacity(0.6))
            if !logic.result.isEmpty { Text(logic.result).font(.title3.bold()).foregroundColor(logic.result.contains("Win") || logic.result.contains("Blackjack") ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed) }
            HStack(spacing: 12) {
                if !logic.gameOver {
                    Button("Hit") { logic.hit() }.font(.headline).foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Stand") { logic.stand() }.font(.headline).foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    if logic.playerHand.count == 2 {
                        Button("Double") { logic.doubleDown() }.font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(GamingDesignTokens.accentPurple, in: Capsule())
                        Button("Surrender") { logic.surrender() }.font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(GamingDesignTokens.dangerRed.opacity(0.7), in: Capsule())
                    }
                } else {
                    Button("New Hand") { logic.newHand() }.font(.headline).foregroundColor(.black).padding(.horizontal, 28).padding(.vertical, 12).background(GamingDesignTokens.accentGold, in: Capsule())
                    Button("End") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
                }
            }
            HStack { Text("Bet:").foregroundColor(.white); Stepper("\(logic.bet)", value: $logic.bet, in: 10...min(200, max(10, ledger.profile.coins)), step: 10).foregroundColor(.white) }.padding(.horizontal, 32)
            Spacer()
        }
    }

    private func cardView(_ card: PlayingCard) -> some View {
        VStack(spacing: 2) {
            Text(card.display).font(.title3.bold()).foregroundColor(card.suit == "♥" || card.suit == "♦" ? .red : .white)
            Text(card.suit).font(.caption)
        }.frame(width: 50, height: 70).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "suit.spade.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Session Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Hands Played", "\(logic.handsPlayed)")
                    statRow("Wins", "\(logic.wins)")
                    statRow("Blackjacks", "\(logic.blackjackCount)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.wins > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
