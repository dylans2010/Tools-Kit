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
        VStack(spacing: 24) {
            Image(systemName: "rectangle.on.rectangle.angled").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Flip Card Duel").font(.title.bold()).foregroundColor(.white)
            Text("War-style card game.\nHigher card wins each round! 10 rounds.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Flip!") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 20) {
            Text("Round \(logic.round)/\(logic.totalRounds)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
            HStack { Text("You: \(logic.playerScore)").foregroundColor(GamingDesignTokens.accentNeon); Spacer(); Text("Opp: \(logic.opponentScore)").foregroundColor(GamingDesignTokens.dangerRed) }.padding(.horizontal, 32)
            HStack(spacing: 40) {
                cardView(rank: logic.playerCard, label: "You", color: GamingDesignTokens.accentNeon)
                Text("VS").font(.title.bold()).foregroundColor(.white)
                cardView(rank: logic.opponentCard, label: "CPU", color: GamingDesignTokens.dangerRed)
            }
            if !logic.result.isEmpty { Text(logic.result).font(.headline).foregroundColor(GamingDesignTokens.accentGold) }
            if !logic.gameOver {
                Button(logic.isFlipping ? "Flipping..." : "FLIP") { logic.flip() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 60).padding(.vertical, 14)
                    .background(logic.isFlipping ? Color.gray : GamingDesignTokens.accentGold, in: Capsule()).disabled(logic.isFlipping)
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
        return VStack(spacing: 20) {
            Image(systemName: won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(won ? "You Win!" : (logic.playerScore == logic.opponentScore ? "Draw!" : "CPU Wins")).font(.title.bold()).foregroundColor(.white)
            Text("\(logic.playerScore) - \(logic.opponentScore)").font(.title2.bold()).foregroundColor(GamingDesignTokens.accentNeon)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: won, score: logic.score, reward: reward) }
    }
}
