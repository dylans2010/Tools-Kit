import SwiftUI

struct TowerDefenseXView: View {
    @StateObject private var logic = TowerDefenseXLogic()
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
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
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "building.columns.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Tower Defense X").font(.title.bold()).foregroundColor(.white)
                Text("Place towers to defend against waves!\nDifficulty affects enemy strength.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                let stats = ledger.gameStats(for: logic.gameIdentifier)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("Wins: \(stats.wins)").font(.caption2).foregroundColor(GamingDesignTokens.successGreen)
                    }
                }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button("\(label) Defense") { logic.startGame(difficulty: idx) }
                            .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(idx == 0 ? GamingDesignTokens.accentNeon : (idx == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed), in: Capsule())
                    }
                }.padding(.horizontal, 32)

                if ledger.canClaimDailyBonus(for: logic.gameIdentifier) {
                    Button { ledger.claimDailyBonus(for: logic.gameIdentifier) } label: {
                        Label("Claim Daily Bonus", systemImage: "gift.fill").font(.subheadline.bold()).foregroundColor(.black)
                            .padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    }
                }
            }.padding()
        }
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

            HStack(spacing: 8) {
                ForEach(TDTower.TowerType.allCases, id: \.self) { type in
                    Button { logic.selectedTowerType = type } label: {
                        VStack(spacing: 2) {
                            Image(systemName: type.icon).font(.caption).foregroundColor(logic.selectedTowerType == type ? GamingDesignTokens.accentNeon : .white.opacity(0.5))
                            Text("\(type.cost)g").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                        }.padding(6).background(logic.selectedTowerType == type ? GamingDesignTokens.accentNeon.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }.padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: logic.gridSize), spacing: 2) {
                ForEach(0..<logic.gridSize * logic.gridSize, id: \.self) { idx in
                    let r = idx / logic.gridSize
                    let c = idx % logic.gridSize
                    let isPath = logic.path.contains(where: { $0.row == r && $0.col == c })
                    let tower = logic.towers.first(where: { $0.row == r && $0.col == c })
                    let hasEnemy = logic.enemies.contains(where: { $0.hp > 0 && $0.pathIndex < logic.path.count && logic.path[$0.pathIndex].row == r && logic.path[$0.pathIndex].col == c })
                    ZStack {
                        Rectangle().fill(isPath ? Color.brown.opacity(0.3) : GamingDesignTokens.cardSurface)
                        if let t = tower { Image(systemName: t.towerType.icon).font(.caption).foregroundColor(GamingDesignTokens.accentPurple) }
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
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(logic.won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.won ? "Victory!" : "Base Destroyed").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Waves Survived", "\(logic.wave)")
                    statRow("Towers Built", "\(logic.towersBuilt)")
                    statRow("Enemies Killed", "\(logic.enemiesKilled)")
                    statRow("Score", "\(logic.score)")
                    statRow("Difficulty", logic.difficulty == 0 ? "Easy" : (logic.difficulty == 1 ? "Medium" : "Hard"))
                    statRow("Streak Multiplier", String(format: "%.1fx", logic.streakMultiplier))
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)
                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold).padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.won, score: logic.score, reward: reward) }
    }

    private var towerCost: Int {
        switch logic.selectedTowerType {
        case .basic: return 50
        case .sniper: return 100
        case .splash: return 75
        case .slow: return 60
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
