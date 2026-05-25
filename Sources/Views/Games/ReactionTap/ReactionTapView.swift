import SwiftUI

struct ReactionTapView: View {
    @StateObject private var logic = ReactionTapLogic()
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
        .navigationTitle("Reaction Tap").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Reaction Tap").font(.title.bold()).foregroundColor(.white)
            Text("Wait for green, then tap as fast as you can!\n5 rounds to test your reflexes.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 0) {
            Text("Round \(logic.round)/\(logic.totalRounds)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon).padding(.top, 8)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(logic.tooEarly ? GamingDesignTokens.dangerRed : (logic.isGreen ? GamingDesignTokens.successGreen : GamingDesignTokens.cardSurface))
                    .frame(height: 300).padding(.horizontal, 32)
                if logic.tooEarly { Text("Too Early!").font(.title.bold()).foregroundColor(.white) }
                else if logic.isGreen { Text("TAP NOW!").font(.title.bold()).foregroundColor(.white) }
                else if logic.waiting { Text("Wait...").font(.title2).foregroundColor(.white.opacity(0.5)) }
                if let rt = logic.reactionTime { Text("\(Int(rt)) ms").font(.system(size: 48, weight: .black, design: .monospaced)).foregroundColor(.white) }
            }.onTapGesture { logic.tap() }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "bolt.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Results").font(.title.bold()).foregroundColor(.white)
            Text("Best: \(Int(logic.bestTime)) ms").foregroundColor(GamingDesignTokens.accentNeon)
            Text("Average: \(Int(logic.averageTime)) ms").foregroundColor(.white.opacity(0.7))
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.bestTime < 300, score: logic.score, reward: reward) }
    }
}
