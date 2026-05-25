import SwiftUI

struct SequenceRecallView: View {
    @StateObject private var logic = SequenceRecallLogic()
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
        .navigationTitle("Sequence Recall").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "waveform.path.ecg").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Sequence Recall").font(.title.bold()).foregroundColor(.white)
                Text("Watch the color sequence, then repeat it.\nLonger sequences at higher difficulty.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)


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
                        Button("\(label) Mode") { logic.startGame(difficulty: idx) }
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


    private let colorMap: [Color] = [.red, .green, .blue, .yellow, .orange, .purple]

    private var gameView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Round \(logic.round)").font(.headline.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.lives > 0 { HStack(spacing: 2) { ForEach(0..<logic.lives, id: \.self) { _ in Image(systemName: "heart.fill").font(.caption2).foregroundColor(GamingDesignTokens.dangerRed) } } }
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)
            if logic.isShowingSequence {
                Text("Watch...").font(.title2.bold()).foregroundColor(.white)
            } else {
                Text("Your turn! (\(logic.playerInput.count)/\(logic.sequence.count))").font(.subheadline).foregroundColor(.white.opacity(0.7))
            }
            let gridCount = min(logic.colorCount, colorMap.count)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<gridCount, id: \.self) { i in
                    let isHighlighted = logic.isShowingSequence && logic.currentShowIndex > 0 && logic.currentShowIndex <= logic.sequence.count && logic.sequence[logic.currentShowIndex - 1] == i
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorMap[i].opacity(isHighlighted ? 1.0 : 0.4))
                        .frame(height: 120).scaleEffect(isHighlighted ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                        .onTapGesture { logic.tapColor(i) }
                }
            }.padding(.horizontal, 32)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
                Text("Game Over").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Reached Round", "\(logic.round)")
                    statRow("Score", "\(logic.score)")
                    statRow("Lives Left", "\(logic.lives)")
                    statRow("Best Round", "\(logic.bestRound)")
                    statRow("Streak Multiplier", "String(format: "%.1fx", logic.streakMultiplier)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.round > 5, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
