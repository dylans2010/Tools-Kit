import SwiftUI

struct MemoryMatchView: View {
    @StateObject private var logic = MemoryMatchLogic()
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
        .navigationTitle("Memory Match").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Memory Match").font(.title.bold()).foregroundColor(.white)
                Text("Find all matching pairs!\nConsecutive matches build combos.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                    Button("4×4 Easy") { logic.startGame(difficulty: 0) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("5×4 Medium") { logic.startGame(difficulty: 1) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentGold, in: Capsule())
                    Button("6×5 Hard") { logic.startGame(difficulty: 2) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.dangerRed, in: Capsule())
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
            HStack {
                Text("Moves: \(logic.moves)").font(.caption.bold()).foregroundColor(.white)
                Spacer()
                if logic.consecutiveMatches > 0 { Text("🔥\(logic.consecutiveMatches)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.timerMode { Text(String(format: "⏱ %.0f", logic.timeRemaining)).font(.caption.bold()).foregroundColor(logic.timeRemaining < 15 ? GamingDesignTokens.dangerRed : .white) }
                Spacer()
                Text("Matched: \(logic.matchedPairs)/\(logic.totalPairs)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
            }.padding(.horizontal)

            let cols = logic.gridCols
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                ForEach(logic.cards.indices, id: \.self) { i in
                    let card = logic.cards[i]
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(card.isMatched ? GamingDesignTokens.successGreen.opacity(0.3) : (card.isFaceUp ? GamingDesignTokens.cardSurface : GamingDesignTokens.accentPurple))
                        if card.isFaceUp || card.isMatched {
                            Text(card.symbol).font(.title2)
                        } else {
                            Image(systemName: "questionmark").font(.headline).foregroundColor(.white.opacity(0.4))
                        }
                    }.frame(height: 56).onTapGesture { logic.flipCard(at: i) }
                }
            }.padding(.horizontal, 8)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text(logic.won ? "All Matched!" : "Time's Up!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Pairs Found", "\(logic.matchedPairs)/\(logic.totalPairs)")
                    statRow("Moves", "\(logic.moves)")
                    statRow("Best Combo", "\(logic.bestConsecutiveMatches)")
                    statRow("Perfect Game", logic.isPerfectGame ? "Yes" : "No")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
