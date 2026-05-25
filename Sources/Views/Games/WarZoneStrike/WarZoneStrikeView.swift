import SwiftUI

struct WarZoneStrikeView: View {
    @StateObject private var logic = WarZoneStrikeLogic()
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
        .navigationTitle("WarZone Strike")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "scope").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
            Text("WarZone Strike").font(.title.bold()).foregroundColor(.white)
            Text("Tap enemies crossing a 3-lane battlefield.\n10 waves of increasing difficulty.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack {
                Text("Best Score:").foregroundColor(.white.opacity(0.6))
                Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            }
            Button("Start Mission") { logic.startGame() }
                .font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14)
                .background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack {
                Text("Wave \(logic.currentWave + 1)/10").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                Text("Lives: \(logic.lives)").font(.caption.bold()).foregroundColor(logic.lives <= 2 ? GamingDesignTokens.dangerRed : .white)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            GeometryReader { geo in
                let laneHeight = geo.size.height / 3
                ZStack {
                    ForEach(0..<3, id: \.self) { lane in
                        Rectangle().fill(Color.white.opacity(lane % 2 == 0 ? 0.03 : 0.06))
                            .frame(height: laneHeight)
                            .offset(y: CGFloat(lane) * laneHeight)
                    }
                    ForEach(logic.enemies) { enemy in
                        Circle()
                            .fill(GamingDesignTokens.dangerRed)
                            .frame(width: 36, height: 36)
                            .overlay(Text("\(enemy.health)").font(.caption2.bold()).foregroundColor(.white))
                            .position(x: CGFloat(enemy.position / 10.0) * geo.size.width,
                                      y: CGFloat(enemy.lane) * laneHeight + laneHeight / 2)
                            .onTapGesture { logic.tapEnemy(enemy) }
                    }
                }
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: logic.currentWave >= 10 ? "trophy.fill" : "xmark.octagon.fill")
                .font(.system(size: 64)).foregroundColor(logic.currentWave >= 10 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(logic.currentWave >= 10 ? "Mission Complete!" : "Mission Failed").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            Text("Waves Survived: \(logic.currentWave)").foregroundColor(.white.opacity(0.7))
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back to Games") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.currentWave >= 10, score: logic.score, reward: reward) }
    }
}
