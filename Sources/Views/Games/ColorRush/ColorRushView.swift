import SwiftUI

struct ColorRushView: View {
    @StateObject private var logic = ColorRushLogic()
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
        .navigationTitle("Color Rush").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "paintpalette.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Color Rush").font(.title.bold()).foregroundColor(.white)
                Text("Match the color shown!\nWrong answers lose time on harder modes.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                let stats = ledger.gameStats(for: logic.gameIdentifier)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("Best: \(stats.highScore)").font(.caption2).foregroundColor(GamingDesignTokens.accentGold)
                    }
                }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button("\(label) Rush") { logic.startGame(difficulty: idx) }
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
        VStack(spacing: 16) {
            gameHeader
            gameTarget
            gameGrid

            if logic.bonusTimeEarned > 0 {
                Text("+\(Int(logic.bonusTimeEarned))s bonus time earned").font(.caption2).foregroundColor(GamingDesignTokens.successGreen)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var gameHeader: some View {
        HStack {
            Text(String(format: "⏱ %.0f", logic.timeRemaining)).font(.caption.bold()).foregroundColor(logic.timeRemaining < 10 ? GamingDesignTokens.dangerRed : .white)
            Spacer()
            if logic.consecutiveCorrect > 0 { Text("🔥\(logic.consecutiveCorrect)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
            Spacer()
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
        }.padding(.horizontal)
    }

    @ViewBuilder
    private var gameTarget: some View {
        VStack(spacing: 8) {
            Text(logic.targetColorName).font(.system(size: 40, weight: .black)).foregroundColor(logic.displayColor)
            Text(logic.mode == 0 ? "Tap the matching color" : "Tap what the word says").font(.caption).foregroundColor(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var gameGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(logic.choices.indices, id: \.self) { index in
                colorButton(at: index)
            }
        }.padding(.horizontal)
    }

    @ViewBuilder
    private func colorButton(at index: Int) -> some View {
        Button {
            logic.selectColor(index)
        } label: {
            RoundedRectangle(cornerRadius: 12)
                .fill(logic.choiceColors[index])
                .frame(height: 60)
                .overlay(
                    Text(logic.choices[index])
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "paintpalette.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Time's Up!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Correct", "\(logic.correctAnswers)/\(logic.totalAnswered)")
                    if logic.totalAnswered > 0 { statRow("Accuracy", String(format: "%.0f%%", Double(logic.correctAnswers) / Double(logic.totalAnswered) * 100)) }
                    statRow("Best Streak", "\(logic.bestConsecutive)")
                    statRow("Bonus Time", "+\(Int(logic.bonusTimeEarned))s")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 100, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}

extension ColorRushLogic {
    var choices: [String] { colorNames }
    var choiceColors: [Color] {
        colorNames.map { name in
            switch name {
            case "Red": return .red
            case "Blue": return .blue
            case "Green": return .green
            case "Yellow": return .yellow
            case "Purple": return .purple
            case "Orange": return .orange
            default: return .gray
            }
        }
    }
}
