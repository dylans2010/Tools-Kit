import SwiftUI

struct ScratchAndWinView: View {
    @StateObject private var logic = ScratchAndWinLogic()
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
        .navigationTitle("Scratch & Win").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles.rectangle.stack").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Scratch & Win").font(.title.bold()).foregroundColor(.white)
                Text("Scratch to reveal symbols.\n3 matching = win! Choose your card tier.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                    Button("Bronze Card (50)") { logic.buyCard(tier: 0) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Silver Card (100)") { logic.buyCard(tier: 1) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentGold, in: Capsule())
                    Button("Gold Card (250)") { logic.buyCard(tier: 2) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.dangerRed, in: Capsule())
                }.padding(.horizontal, 32)

                if logic.freeCardsAvailable > 0 {
                    Button("FREE Card (\(logic.freeCardsAvailable) left)") { logic.buyCard(tier: 0) }.font(.headline).foregroundColor(.black).padding(.horizontal, 32).padding(.vertical, 12).background(GamingDesignTokens.successGreen, in: Capsule())
                }

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
            Text("Tap tiles to scratch!").font(.headline).foregroundColor(GamingDesignTokens.accentNeon)
            if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins) streak").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(logic.tiles.enumerated()), id: \.offset) { idx, tile in
                    Button { withAnimation { logic.revealTile(idx) } } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(tile.revealed ? GamingDesignTokens.cardSurface : GamingDesignTokens.accentGold)
                            if tile.revealed { Image(systemName: tile.symbol.icon).font(.system(size: 32)).foregroundColor(.white) }
                            else { Image(systemName: "sparkle").font(.title).foregroundColor(.black.opacity(0.4)) }
                        }.frame(height: 90)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 32)
            Button("Reveal All") { logic.revealAll() }.font(.caption).foregroundColor(GamingDesignTokens.accentNeon)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.lastWin > 0 ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(logic.lastWin > 0 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.lastWin > 0 ? "Winner!" : "No Match").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    if logic.lastWin > 0 { statRow("This Card", "+\(logic.lastWin) coins") }
                    statRow("Total Winnings", "\(logic.totalWinnings)")
                    statRow("Biggest Win", "\(logic.biggestWin)")
                    statRow("Best Streak", "\(logic.bestConsecutiveWins)")
                    statRow("Cards Scratched", "\(logic.cardsScratched)")
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)
                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold).padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button("Buy Another") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.lastWin > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
