import SwiftUI

struct BlackjackProView: View {
    @StateObject private var logic = BlackjackProLogic()
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
        .navigationTitle("Blackjack Pro").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "suit.spade.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Blackjack Pro").font(.title.bold()).foregroundColor(.white)
            Text("Full blackjack: Hit, Stand, Double Down, Split.\nDealer hits on soft 16.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start Session") { logic.startSession() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 12) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            VStack(spacing: 4) {
                Text("Dealer (\(logic.dealerRevealed ? "\(blackjackHandValue(logic.dealerHand))" : "?"))").font(.caption.bold()).foregroundColor(GamingDesignTokens.dangerRed)
                HStack { ForEach(Array(logic.dealerHand.enumerated()), id: \.element.id) { idx, card in
                    Text(idx == 0 || logic.dealerRevealed ? card.display : "🂠").font(.title).padding(4).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6))
                }}
            }
            Divider().background(Color.white.opacity(0.2))
            VStack(spacing: 4) {
                Text("You (\(blackjackHandValue(logic.playerHand)))").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                HStack { ForEach(logic.playerHand) { card in Text(card.display).font(.title).padding(4).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 6)) }}
            }
            if logic.result != .playing {
                Text(logic.result.rawValue).font(.title2.bold()).foregroundColor(logic.result == .playerWin || logic.result == .blackjack ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Button("Next Hand") { logic.dealNewHand() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
            } else {
                HStack(spacing: 12) {
                    Button("Hit") { logic.hit() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Stand") { logic.stand() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    if logic.canDoubleDown {
                        Button("Double") { logic.doubleDown() }.font(.headline).foregroundColor(.black).padding(.horizontal, 16).padding(.vertical, 10).background(GamingDesignTokens.accentPurple, in: Capsule())
                    }
                }
            }
            HStack { Text("Bet: \(logic.bet)").foregroundColor(.white); Spacer()
                Stepper("", value: $logic.bet, in: 10...min(1000, ledger.profile.coins), step: 10).labelsHidden()
            }.padding(.horizontal, 24)
            Button("End Session") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "suit.spade.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Session Over").font(.title.bold()).foregroundColor(.white)
            Text("Hands: \(logic.handsPlayed) | Won: \(logic.score) coins").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 0, score: logic.score, reward: reward) }
    }
}
