import SwiftUI

struct TriviaCrushView: View {
    @StateObject private var logic = TriviaCrushLogic()
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
        .navigationTitle("Trivia Crush").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "questionmark.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Trivia Crush").font(.title.bold()).foregroundColor(.white)
                Text("Test your knowledge across categories.\nHigher difficulty = harder questions + timer.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

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
                        Button("\(label) Trivia") { logic.startGame(difficulty: idx) }
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
            HStack {
                Text("Q\(logic.currentIndex + 1)/\(logic.questions.count)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                if logic.consecutiveCorrect > 0 { Text("🔥\(logic.consecutiveCorrect)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentGold) }
                Spacer()
                Text("\(logic.correctAnswers) correct").font(.caption).foregroundColor(GamingDesignTokens.successGreen)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            if logic.timerRemaining > 0 {
                Text(String(format: "⏱ %.0f", logic.timerRemaining)).font(.caption.bold()).foregroundColor(logic.timerRemaining < 5 ? GamingDesignTokens.dangerRed : .white.opacity(0.6))
            }

            if let q = logic.currentQuestion {
                Text(q.category).font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple).padding(.horizontal, 12).padding(.vertical, 4).background(GamingDesignTokens.accentPurple.opacity(0.15), in: Capsule())
                Text(q.question).font(.headline).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal)
                VStack(spacing: 10) {
                    ForEach(Array(q.answers.enumerated()), id: \.offset) { idx, answer in
                        Button { logic.selectAnswer(idx) } label: {
                            HStack {
                                Text(answer).font(.subheadline).foregroundColor(.white)
                                Spacer()
                                if logic.selectedAnswer != nil {
                                    if idx == q.correctIndex { Image(systemName: "checkmark.circle.fill").foregroundColor(GamingDesignTokens.successGreen) }
                                    else if idx == logic.selectedAnswer { Image(systemName: "xmark.circle.fill").foregroundColor(GamingDesignTokens.dangerRed) }
                                }
                            }.padding(14).background(answerColor(idx, q: q), in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).disabled(logic.selectedAnswer != nil)
                    }
                }.padding(.horizontal)
            }
            Spacer()
        }
    }

    private func answerColor(_ idx: Int, q: TriviaQuestion) -> Color {
        guard let selected = logic.selectedAnswer else { return GamingDesignTokens.cardSurface }
        if idx == q.correctIndex { return GamingDesignTokens.successGreen.opacity(0.3) }
        if idx == selected { return GamingDesignTokens.dangerRed.opacity(0.3) }
        return GamingDesignTokens.cardSurface
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
                Text("Round Complete!").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Correct", "\(logic.correctAnswers)/\(logic.questions.count)")
                    statRow("Best Streak", "\(logic.bestConsecutiveCorrect)")
                    statRow("Accuracy", String(format: "%.0f%%", logic.questions.isEmpty ? 0 : Double(logic.correctAnswers) / Double(logic.questions.count) * 100))
                    statRow("Score", "\(logic.score)")
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
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.correctAnswers > 5, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
