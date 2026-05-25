import SwiftUI

struct DiceRollFortuneView: View {
    @StateObject private var logic = DiceRollFortuneLogic()
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
        .navigationTitle("Dice Roll Fortune").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "dice.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Dice Roll Fortune").font(.title.bold()).foregroundColor(.white)
            Text("Roll dice for winning combinations.\nPair, Three of a Kind, Full House, Straight!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Roll Dice") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack(spacing: 16) { ForEach(Array(logic.dice.enumerated()), id: \.offset) { _, value in
                Text("\(value)").font(.system(size: 48, weight: .black, design: .monospaced)).foregroundColor(.white)
                    .frame(width: 64, height: 64).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                    .rotationEffect(.degrees(logic.isRolling ? 360 : 0)).animation(.easeInOut(duration: 0.06).repeatCount(logic.isRolling ? 100 : 0), value: logic.isRolling)
            }}
            if !logic.combination.isEmpty { Text(logic.combination).font(.title2.bold()).foregroundColor(logic.lastWin > 0 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed) }
            if logic.lastWin > 0 { Text("+\(logic.lastWin) coins").font(.headline).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText()) }
            Stepper("Dice: \(logic.diceCount)", value: $logic.diceCount, in: 2...5).foregroundColor(.white).padding(.horizontal, 24)
            HStack { Text("Bet:").foregroundColor(.white); Stepper("\(logic.bet)", value: $logic.bet, in: 10...min(200, ledger.profile.coins), step: 10).foregroundColor(.white) }.padding(.horizontal, 24)
            Button(logic.isRolling ? "Rolling..." : "ROLL") { logic.roll() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 60).padding(.vertical, 14).background(logic.isRolling ? Color.gray : GamingDesignTokens.accentGold, in: Capsule()).disabled(logic.isRolling)
            Button("End") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Text("Session Over").font(.title.bold()).foregroundColor(.white)
            Text("Rolls: \(logic.rolls) | Won: \(logic.totalWon)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.totalWon > 0, score: logic.score, reward: reward) }
    }
}
