import SwiftUI

struct TacticalRaidView: View {
    @StateObject private var logic = TacticalRaidLogic()
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
            if xpEngine.didLevelUp {
                LevelUpPopupView(level: xpEngine.newLevel, bonusCoins: xpEngine.bonusCoinsAwarded) { xpEngine.clearLevelUp() }
            }
        }
        .navigationTitle("Tactical Raid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.shield.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
            Text("Tactical Raid").font(.title.bold()).foregroundColor(.white)
            Text("1v1 turn-based card battle using 20 action cards.\nOutplay your opponent with strategy.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start Raid") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack { Text("You").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                    Text("HP: \(logic.playerHealth)").font(GamingDesignTokens.fontMono).foregroundColor(.white).contentTransition(.numericText()) }
                Spacer()
                Text("\(logic.message)").font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(2).multilineTextAlignment(.center)
                Spacer()
                VStack { Text("Enemy").font(.caption.bold()).foregroundColor(GamingDesignTokens.dangerRed)
                    Text("HP: \(logic.enemyHealth)").font(GamingDesignTokens.fontMono).foregroundColor(.white).contentTransition(.numericText()) }
            }.padding(.horizontal)

            if let pc = logic.lastPlayerCard, let ec = logic.lastEnemyCard {
                HStack(spacing: 40) {
                    cardDisplay(pc, color: GamingDesignTokens.accentNeon)
                    Text("VS").font(.caption.bold()).foregroundColor(.white.opacity(0.5))
                    cardDisplay(ec, color: GamingDesignTokens.dangerRed)
                }.padding(.vertical, 8)
            }

            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            Divider().background(Color.white.opacity(0.2))
            Text("Your Hand (\(logic.playerHand.count) cards)").font(.caption.bold()).foregroundColor(.white.opacity(0.6))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(logic.playerHand) { card in
                        Button { logic.playCard(card) } label: { cardDisplay(card, color: GamingDesignTokens.accentNeon) }.buttonStyle(.plain)
                    }
                }.padding(.horizontal)
            }
            Spacer()
        }
    }

    private func cardDisplay(_ card: TRCard, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: card.icon).font(.title3).foregroundColor(color)
            Text(card.name).font(.system(size: 10, weight: .bold)).foregroundColor(.white).lineLimit(1)
            Text("\(card.type.rawValue.capitalized) \(card.power)").font(.system(size: 9)).foregroundColor(color.opacity(0.8))
        }
        .frame(width: 70, height: 80)
        .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.4), lineWidth: 1))
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: logic.playerWon ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64)).foregroundColor(logic.playerWon ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(logic.playerWon ? "Victory!" : "Defeated").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.playerWon, score: logic.score, reward: reward) }
    }
}
