import SwiftUI

struct BattlefieldCommanderView: View {
    @StateObject private var logic = BattlefieldCommanderLogic()
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GamingDesignTokens.background.ignoresSafeArea()
            switch logic.phase {
            case .lobby: lobbyView
            case .placement: EmptyView()
            case .playing: gameView
            case .results: resultsView
            }
            if xpEngine.didLevelUp {
                LevelUpPopupView(level: xpEngine.newLevel, bonusCoins: xpEngine.bonusCoinsAwarded) { xpEngine.clearLevelUp() }
            }
        }
        .navigationTitle("Battlefield Commander").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "shield.lefthalf.filled").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
                Text("Battlefield Commander").font(.title.bold()).foregroundColor(.white)
                Text("Turn-based grid tactics on a 10×10 board.\nPlace units, attack enemies, capture the field.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                gameLevelBadge

                HStack {
                    Text("Best Score:").foregroundColor(.white.opacity(0.6))
                    Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
                }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button("\(label) Battle") { logic.startGame(difficulty: idx) }
                            .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(idx == 0 ? GamingDesignTokens.accentNeon : (idx == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed), in: Capsule())
                    }
                }.padding(.horizontal, 32)

                dailyBonusButton
            }.padding()
        }
    }

    private var gameLevelBadge: some View {
        let stats = ledger.gameStats(for: logic.gameIdentifier)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Wins: \(stats.wins)").font(.caption2).foregroundColor(GamingDesignTokens.successGreen)
            }
        }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))
    }

    private var dailyBonusButton: some View {
        Group {
            if ledger.canClaimDailyBonus(for: logic.gameIdentifier) {
                Button { ledger.claimDailyBonus(for: logic.gameIdentifier) } label: {
                    Label("Claim Daily Bonus", systemImage: "gift.fill").font(.subheadline.bold()).foregroundColor(.black)
                        .padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                }
            }
        }
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            HStack {
                Text(logic.isPlayerTurn ? "Your Turn" : "Enemy Turn").font(.caption.bold())
                    .foregroundColor(logic.isPlayerTurn ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed)
                Spacer()
                if logic.streakMultiplier > 1.0 {
                    Text("×\(String(format: "%.1f", logic.streakMultiplier))").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple)
                }
                Text("Wave \(logic.currentWave)/\(logic.totalWaves)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal, 16)

            gridView
        }
    }

    private var gridView: some View {
        GeometryReader { geo in
            let cellSize = min(geo.size.width, geo.size.height - 20) / CGFloat(logic.gridSize)
            VStack(spacing: 0) {
                ForEach(0..<logic.gridSize, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<logic.gridSize, id: \.self) { col in
                            cellView(row: row, col: col, size: cellSize)
                        }
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cellView(row: Int, col: Int, size: CGFloat) -> some View {
        let playerUnit = logic.playerUnits.first { $0.row == row && $0.col == col }
        let enemyUnit = logic.enemyUnits.first { $0.row == row && $0.col == col }
        let isSelected = logic.selectedUnit?.row == row && logic.selectedUnit?.col == col
        return ZStack {
            Rectangle().fill((row + col) % 2 == 0 ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                .border(isSelected ? GamingDesignTokens.accentNeon : Color.white.opacity(0.1), width: isSelected ? 2 : 0.5)
            if let unit = playerUnit {
                VStack(spacing: 0) {
                    Image(systemName: unit.type.icon).font(.system(size: size * 0.35)).foregroundColor(GamingDesignTokens.accentNeon)
                    Text("\(unit.health)").font(.system(size: 8).monospacedDigit()).foregroundColor(.white)
                }
            } else if let unit = enemyUnit {
                VStack(spacing: 0) {
                    Image(systemName: unit.type.icon).font(.system(size: size * 0.35)).foregroundColor(GamingDesignTokens.dangerRed)
                    Text("\(unit.health)").font(.system(size: 8).monospacedDigit()).foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .onTapGesture {
            if let pu = playerUnit { logic.selectUnit(pu) }
            else if logic.selectedUnit != nil { logic.moveUnit(to: row, col: col) }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.playerWon ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64))
                    .foregroundColor(logic.playerWon ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.playerWon ? "Victory!" : "Defeated").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Difficulty", logic.difficulty == 0 ? "Easy" : (logic.difficulty == 1 ? "Medium" : "Hard"))
                    statRow("Waves Survived", "\(logic.currentWave)/\(logic.totalWaves)")
                    statRow("Streak Multiplier", String(format: "%.1fx", logic.streakMultiplier))
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)

                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold)
                        .padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }

                HStack(spacing: 16) {
                    Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black)
                        .padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back to Games") { dismiss() }.font(.headline).foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.playerWon, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
