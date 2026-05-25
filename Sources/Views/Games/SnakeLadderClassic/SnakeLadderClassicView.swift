import SwiftUI

struct SnakeLadderClassicView: View {
    @StateObject private var logic = SnakeLadderClassicLogic()
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
        .navigationTitle("Snakes & Ladders").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Snakes & Ladders").font(.title.bold()).foregroundColor(.white)
            Text("Classic board game vs CPU.\nRoll dice, avoid snakes, climb ladders!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start Game") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            ForEach(logic.players) { p in
                HStack {
                    Circle().fill(p.isHuman ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed).frame(width: 12, height: 12)
                    Text("\(p.name): \(p.position)").foregroundColor(.white).font(.headline)
                    if logic.currentPlayerIndex < logic.players.count && logic.players[logic.currentPlayerIndex].id == p.id { Text("← turn").font(.caption).foregroundColor(GamingDesignTokens.accentGold) }
                }
            }
            if logic.lastDice > 0 {
                Text("🎲 \(logic.lastDice)").font(.system(size: 48, weight: .black)).foregroundColor(.white)
            }
            if !logic.message.isEmpty { Text(logic.message).font(.subheadline).foregroundColor(GamingDesignTokens.accentNeon).multilineTextAlignment(.center).padding(.horizontal) }
            if !logic.gameOver && logic.currentPlayerIndex < logic.players.count && logic.players[logic.currentPlayerIndex].isHuman {
                Button("Roll Dice") { logic.rollDice() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 60).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }.padding()
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            let won = logic.winner?.isHuman == true
            Image(systemName: won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(won ? "You Win!" : "CPU Wins!").font(.title.bold()).foregroundColor(.white)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.winner?.isHuman == true, score: logic.score, reward: reward) }
    }
}
