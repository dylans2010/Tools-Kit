import SwiftUI

struct WordStormView: View {
    @StateObject private var logic = WordStormLogic()
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
        .navigationTitle("Word Storm").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "textformat.abc").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Word Storm").font(.title.bold()).foregroundColor(.white)
            Text("Unscramble words before time runs out!").font(.subheadline).foregroundColor(.white.opacity(0.7))
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(format: "%.1f", logic.timeRemaining) + "s").font(GamingDesignTokens.fontMono).foregroundColor(logic.timeRemaining < 10 ? GamingDesignTokens.dangerRed : .white)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            Text("Solved: \(logic.solvedWords.count)/\(logic.wordsToSolve)").font(.caption).foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                ForEach(Array(logic.scrambledLetters.enumerated()), id: \.offset) { idx, letter in
                    Button { logic.tapLetter(idx) } label: {
                        Text(String(letter).uppercased()).font(.title.bold()).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(GamingDesignTokens.accentPurple, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Text(logic.playerInput.uppercased()).font(.title2.bold().monospaced()).foregroundColor(GamingDesignTokens.accentNeon).frame(height: 40)

            HStack(spacing: 16) {
                Button("Clear") { logic.clearInput() }.foregroundColor(GamingDesignTokens.dangerRed)
                Button("Submit") { logic.submitAnswer() }.font(.headline).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "textformat.abc").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Time's Up!").font(.title.bold()).foregroundColor(.white)
            Text("Words Solved: \(logic.solvedWords.count)").foregroundColor(GamingDesignTokens.accentNeon)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.solvedWords.count > 0, score: logic.score, reward: reward) }
    }
}
