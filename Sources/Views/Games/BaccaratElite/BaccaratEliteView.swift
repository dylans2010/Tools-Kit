import SwiftUI

struct BaccaratEliteView: View {
    @StateObject private var logic = BaccaratEliteLogic()
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
        .navigationTitle("Baccarat Elite").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "suit.heart.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
                Text("Baccarat Elite").font(.title.bold()).foregroundColor(.white)

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
                Text("Hand \(logic.round)/\(logic.totalRounds)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                Spacer()
                Text("Balance: \(logic.balance)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            }.padding(.horizontal)

            if !logic.playerCards.isEmpty {
                HStack(spacing: 30) {
                    VStack { Text("Player").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        HStack { ForEach(logic.playerCards, id: \.self) { c in Text(logic.cardDisplay(c)).font(.title3.bold()).foregroundColor(.white).frame(width: 36, height: 48).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6)) } }
                        Text("\(logic.playerTotal)").font(.headline).foregroundColor(.white) }
                    VStack { Text("Banker").font(.caption.bold()).foregroundColor(GamingDesignTokens.dangerRed)
                        HStack { ForEach(logic.bankerCards, id: \.self) { c in Text(logic.cardDisplay(c)).font(.title3.bold()).foregroundColor(.white).frame(width: 36, height: 48).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6)) } }
                        Text("\(logic.bankerTotal)").font(.headline).foregroundColor(.white) }
                }
            }

            if !logic.result.isEmpty { Text(logic.result).font(.headline).foregroundColor(GamingDesignTokens.accentGold) }

            if logic.bet == nil {
                Text("Place your bet").font(.caption).foregroundColor(.white.opacity(0.6))
                HStack(spacing: 12) {
                    ForEach(["Player", "Banker", "Tie"], id: \.self) { type in
                        Button(type) { logic.placeBet(type == "Player" ? .player : (type == "Banker" ? .banker : .tie)) }
                            .font(.headline).foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(type == "Tie" ? GamingDesignTokens.accentGold : GamingDesignTokens.accentNeon, in: Capsule())
                    }
                }
            } else if logic.roundOver {
                Button("Next Hand") { logic.nextHand() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.won ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64)).foregroundColor(logic.won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.won ? "Victory!" : "Defeated").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Hands Won", "\(logic.handsWon)/\(logic.round)")
                    statRow("Final Balance", "\(logic.balance)")
                    statRow("Biggest Win", "\(logic.biggestWin)")
                    statRow("Best Streak", "\(logic.bestStreak)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
