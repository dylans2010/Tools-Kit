import SwiftUI

struct SlotMachineGoldView: View {
    @StateObject private var logic = SlotMachineGoldLogic()
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
        .navigationTitle("Slot Machine Gold").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Slot Machine Gold").font(.title.bold()).foregroundColor(.white)
                Text("3-reel slot machine with jackpots.\nMatch symbols for big wins!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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

                payoutTable

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                Button("Play Slots") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()

                if ledger.canClaimDailyBonus(for: logic.gameIdentifier) {
                    Button { ledger.claimDailyBonus(for: logic.gameIdentifier) } label: {
                        Label("Claim Daily Bonus", systemImage: "gift.fill").font(.subheadline.bold()).foregroundColor(.black)
                            .padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    }
                }
            }.padding()
        }
    }

    private var payoutTable: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Payout Table").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
            ForEach(SlotSymbol.allSymbols, id: \.name) { sym in
                HStack {
                    Image(systemName: sym.icon).font(.caption).foregroundColor(GamingDesignTokens.accentGold)
                    Text("3x \(sym.name)").font(.caption2).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(sym.multiplier))x bet").font(.caption2.bold()).foregroundColor(GamingDesignTokens.accentGold)
                }
            }
        }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var gameView: some View {
        VStack(spacing: 20) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { i in
                    VStack {
                        Image(systemName: logic.reels[i].icon).font(.system(size: 40)).foregroundColor(GamingDesignTokens.accentGold)
                            .frame(width: 80, height: 80).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                            .scaleEffect(logic.isSpinning ? 0.9 : 1.0).animation(.easeInOut(duration: 0.08).repeatCount(logic.isSpinning ? 100 : 0, autoreverses: true), value: logic.isSpinning)
                        Text(logic.reels[i].name).font(.caption2).foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            if logic.lastWin > 0 { Text("WIN: \(logic.lastWin) coins!").font(.title2.bold()).foregroundColor(GamingDesignTokens.accentGold).transition(.scale).contentTransition(.numericText()) }

            HStack(spacing: 12) {
                if logic.consecutiveWins > 0 { Text("🔥\(logic.consecutiveWins)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                if logic.freeSpinsAvailable > 0 { Text("Free: \(logic.freeSpinsAvailable)").font(.caption.bold()).foregroundColor(GamingDesignTokens.successGreen) }
                if logic.jackpotProgress > 0.5 { ProgressView(value: logic.jackpotProgress).tint(GamingDesignTokens.accentGold).frame(width: 80) }
            }

            HStack {
                Text("Bet:").foregroundColor(.white)
                Stepper("\(logic.bet)", value: $logic.bet, in: logic.minBet...min(logic.maxBet, max(logic.minBet, ledger.profile.coins)), step: 10).foregroundColor(.white)
            }.padding(.horizontal, 32)

            Button(logic.isSpinning ? "Spinning..." : (logic.freeSpinsAvailable > 0 ? "FREE SPIN" : "SPIN")) { logic.spin() }
                .font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 60).padding(.vertical, 16)
                .background(logic.isSpinning ? Color.gray : (logic.freeSpinsAvailable > 0 ? GamingDesignTokens.successGreen : GamingDesignTokens.accentGold), in: Capsule()).disabled(logic.isSpinning)
            Button("End Session") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Session Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Spins", "\(logic.spins)")
                    statRow("Total Won", "\(logic.totalWon)")
                    statRow("Biggest Win", "\(logic.biggestWin)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.totalWon > 0, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
