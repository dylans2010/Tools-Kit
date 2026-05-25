import SwiftUI

struct RouletteRoyalView: View {
    @StateObject private var logic = RouletteRoyalLogic()
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
        .navigationTitle("Roulette Royal").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
            Text("Roulette Royal").font(.title.bold()).foregroundColor(.white)
            Text("European roulette (single zero).\nStraight, red/black, odd/even, and more.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Spin the Wheel") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            if let r = logic.result {
                let isRed = RouletteRoyalLogic.redNumbers.contains(r)
                Text("\(r)").font(.system(size: 64, weight: .black)).foregroundColor(r == 0 ? GamingDesignTokens.successGreen : (isRed ? GamingDesignTokens.dangerRed : .white))
                    .scaleEffect(logic.isSpinning ? 0.8 : 1.0).animation(.easeInOut(duration: 0.06).repeatCount(logic.isSpinning ? 100 : 0, autoreverses: true), value: logic.isSpinning)
            }
            if logic.lastWin > 0 { Text("WIN: \(logic.lastWin) coins!").font(.title3.bold()).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText()) }
            Picker("Bet Type", selection: $logic.selectedBetType) { ForEach(RouletteBetType.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu).tint(GamingDesignTokens.accentNeon)
            if logic.selectedBetType == .straight {
                Stepper("Number: \(logic.straightNumber)", value: $logic.straightNumber, in: 0...36).foregroundColor(.white).padding(.horizontal, 24)
            }
            HStack { Text("Bet:").foregroundColor(.white); Stepper("\(logic.bet)", value: $logic.bet, in: 5...min(1000, ledger.profile.coins), step: 5).foregroundColor(.white) }.padding(.horizontal, 24)
            Button(logic.isSpinning ? "Spinning..." : "SPIN") { logic.spin() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 60).padding(.vertical, 14)
                .background(logic.isSpinning ? Color.gray : GamingDesignTokens.dangerRed, in: Capsule()).disabled(logic.isSpinning)
            Button("End Session") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Text("Session Over").font(.title.bold()).foregroundColor(.white)
            Text("Spins: \(logic.spins) | Won: \(logic.totalWon)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.totalWon > 0, score: logic.score, reward: reward) }
    }
}
