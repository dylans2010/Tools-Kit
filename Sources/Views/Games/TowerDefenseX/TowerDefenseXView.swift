import SwiftUI

struct TowerDefenseXView: View {
    @StateObject private var logic = TowerDefenseXLogic()
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
        .navigationTitle("Tower Defense X").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.columns.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Tower Defense X").font(.title.bold()).foregroundColor(.white)
            Text("Place towers to defend against waves!\n10 waves to survive.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Defend!") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Wave \(logic.wave)/\(logic.totalWaves)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                Text("❤️ \(logic.lives)").font(.caption.bold()).foregroundColor(GamingDesignTokens.dangerRed)
                Spacer()
                Text("💰 \(logic.gold)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold)
                Spacer()
                Text("\(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            }.padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: logic.gridSize), spacing: 2) {
                ForEach(0..<logic.gridSize * logic.gridSize, id: \.self) { idx in
                    let r = idx / logic.gridSize; let c = idx % logic.gridSize
                    let isPath = logic.path.contains(where: { $0.row == r && $0.col == c })
                    let hasTower = logic.towers.contains(where: { $0.row == r && $0.col == c })
                    let hasEnemy = logic.enemies.contains(where: { $0.hp > 0 && $0.pathIndex < logic.path.count && logic.path[$0.pathIndex].row == r && logic.path[$0.pathIndex].col == c })
                    ZStack {
                        Rectangle().fill(isPath ? Color.brown.opacity(0.3) : GamingDesignTokens.cardSurface)
                        if hasTower { Image(systemName: "building.columns.fill").font(.caption).foregroundColor(GamingDesignTokens.accentPurple) }
                        if hasEnemy { Circle().fill(GamingDesignTokens.dangerRed).frame(width: 12) }
                    }.frame(height: 36).onTapGesture { logic.placeTower(row: r, col: c) }
                }
            }.padding(.horizontal, 8)
            if !logic.waveInProgress {
                Button("Start Wave \(logic.wave + 1)") { logic.startWave() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: logic.won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(logic.won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(logic.won ? "Victory!" : "Base Destroyed").font(.title.bold()).foregroundColor(.white)
            Text("Wave: \(logic.wave) | Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }
}
