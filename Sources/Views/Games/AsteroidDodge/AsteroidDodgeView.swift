import SwiftUI

struct AsteroidDodgeView: View {
    @StateObject private var logic = AsteroidDodgeLogic()
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
        .navigationTitle("Asteroid Dodge").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Asteroid Dodge").font(.title.bold()).foregroundColor(.white)
            Text("Dodge falling asteroids!\nDrag to move your ship.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Launch!") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        GeometryReader { geo in
            ZStack {
                Text("\(logic.score)").font(.system(size: 60, weight: .black, design: .monospaced)).foregroundColor(.white.opacity(0.1))
                ForEach(logic.asteroids) { a in
                    Circle().fill(Color.gray.opacity(0.7)).frame(width: a.size, height: a.size)
                        .position(x: a.x * geo.size.width, y: a.y * geo.size.height)
                }
                Image(systemName: "arrowtriangle.up.fill").font(.system(size: 30)).foregroundColor(GamingDesignTokens.accentNeon)
                    .position(x: logic.playerX * geo.size.width, y: geo.size.height * 0.85)
            }
            .gesture(DragGesture().onChanged { v in logic.movePlayer(to: v.location.x / geo.size.width) })
            .overlay(alignment: .top) {
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).padding(8).contentTransition(.numericText())
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "sparkles").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Crash!").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 300, score: logic.score, reward: reward) }
    }
}
