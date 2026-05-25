import SwiftUI

struct TriviaCrushView: View {
    @StateObject private var logic = TriviaCrushLogic()
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
        .navigationTitle("Trivia Crush").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Trivia Crush").font(.title.bold()).foregroundColor(.white)
            Text("10 questions per round.\n6 categories to test your knowledge.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start Trivia") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HStack { Text("Q\(logic.currentIndex + 1)/\(logic.questions.count)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer(); Text("\(logic.correctAnswers) correct").font(.caption).foregroundColor(GamingDesignTokens.successGreen)
                Spacer(); Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

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
        return VStack(spacing: 20) {
            Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Round Complete!").font(.title.bold()).foregroundColor(.white)
            Text("\(logic.correctAnswers)/\(logic.questions.count) Correct").font(.title2).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.correctAnswers > 5, score: logic.score, reward: reward) }
    }
}
