import SwiftUI

struct ConnectFourBlitzView: View {
    @StateObject private var logic = ConnectFourBlitzLogic()
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
        .navigationTitle("Connect Four").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.grid.3x3.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
                Text("Connect Four Blitz").font(.title.bold()).foregroundColor(.white)
                Text("Drop pieces to connect four in a row!\n3 AI difficulty levels.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Match") { logic.startGame(difficulty: idx) }
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
            HStack {
                Text("Wins: \(logic.wins)").foregroundColor(GamingDesignTokens.successGreen)
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                Spacer()
                Text("Round \(logic.games)/\(logic.totalRounds)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            }.padding(.horizontal)

            HStack(spacing: 2) {
                ForEach(0..<logic.cols, id: \.self) { c in
                    Button { logic.dropPiece(col: c) } label: {
                        VStack(spacing: 2) {
                            ForEach(0..<logic.rows, id: \.self) { r in
                                let val = r < logic.board.count && c < logic.board[r].count ? logic.board[r][c] : 0
                                Circle().fill(val == 1 ? GamingDesignTokens.accentNeon : (val == 2 ? GamingDesignTokens.dangerRed : Color.white.opacity(0.1)))
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(8).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

            if logic.gameOver {
                Text(logic.winner == 1 ? "You Win!" : (logic.winner == 2 ? "CPU Wins" : "Draw")).font(.title2.bold()).foregroundColor(logic.winner == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                HStack(spacing: 16) {
                    Button("Next") { logic.newRound() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("End") { logic.endSession() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 10).background(Color.white.opacity(0.15), in: Capsule())
                }
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.grid.3x3.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
                Text("Session Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Wins", "\(logic.wins)/\(logic.games)")
                    statRow("Losses", "\(logic.losses)")
                    statRow("Draws", "\(logic.draws)")
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
