import SwiftUI

struct FlipCardDuelView: View {
    @StateObject private var logic = FlipCardDuelLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    private let rankNames = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

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
        .navigationTitle("Flip Card Duel").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.on.rectangle.angled").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Flip Card Duel").font(.title.bold()).foregroundColor(.white)
                Text("War-style card game with double-or-nothing.\nHigher card wins each round!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Duel") { logic.startGame(difficulty: idx) }
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
        VStack(spacing: 20) {
            HStack {
                Text("Round \(logic.round)/\(logic.totalRounds)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.doubleOrNothingActive { Text("×2 ACTIVE").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple) }
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            }.padding(.horizontal)

            HStack { Text("You: \(logic.playerScore)").foregroundColor(GamingDesignTokens.accentNeon); Spacer(); Text("Wars: \(logic.warCount)").font(.caption2).foregroundColor(.white.opacity(0.6)); Spacer(); Text("Opp: \(logic.opponentScore)").foregroundColor(GamingDesignTokens.dangerRed) }.padding(.horizontal, 32)

            HStack(spacing: 40) {
                cardView(rank: logic.playerCard, label: "You", color: GamingDesignTokens.accentNeon)
                Text("VS").font(.title.bold()).foregroundColor(.white)
                cardView(rank: logic.opponentCard, label: "CPU", color: GamingDesignTokens.dangerRed)
            }
            if !logic.result.isEmpty { Text(logic.result).font(.headline).foregroundColor(GamingDesignTokens.accentGold) }
            if !logic.gameOver {
                HStack(spacing: 12) {
                    Button(logic.isFlipping ? "Flipping..." : "FLIP") { logic.flip() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 40).padding(.vertical, 14)
                        .background(logic.isFlipping ? Color.gray : GamingDesignTokens.accentGold, in: Capsule()).disabled(logic.isFlipping)
                    if logic.consecutiveWins >= 2 && !logic.doubleOrNothingActive {
                        Button("Double") { logic.activateDoubleOrNothing() }.font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                            .background(GamingDesignTokens.accentPurple, in: Capsule())
                    }
                }
            }
            Spacer()
        }
    }

    private func cardView(rank: Int, label: String, color: Color) -> some View {
        VStack {
            Text(label).font(.caption).foregroundColor(color)
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(GamingDesignTokens.cardSurface).frame(width: 80, height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 2))
                Text(rank > 0 && rank < rankNames.count ? rankNames[rank] : "?").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        let won = logic.playerScore > logic.opponentScore
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(won ? "You Win!" : (logic.playerScore == logic.opponentScore ? "Draw!" : "CPU Wins")).font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Final Score", "\(logic.playerScore) - \(logic.opponentScore)")
                    statRow("Points", "\(logic.score)")
                    statRow("Wars", "\(logic.warCount)")
                    statRow("War Wins", "\(logic.warWins)")
                    statRow("Best Streak", "\(logic.bestConsecutiveWins)")
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
