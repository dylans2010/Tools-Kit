import SwiftUI

struct SequenceRecallView: View {
    @StateObject private var logic = SequenceRecallLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    private let colorMap: [Color] = [.red, .green, .blue, .yellow]

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
        VStack(spacing: 24) {
            Image(systemName: "waveform.path.ecg").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Sequence Recall").font(.title.bold()).foregroundColor(.white)
            Text("Watch the color sequence, then repeat it.\nSequence grows each round.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Round \(logic.round)").font(.headline.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)
            if logic.isShowingSequence {
                Text("Watch...").font(.title2.bold()).foregroundColor(.white)
            } else {
                Text("Your turn! (\(logic.playerInput.count)/\(logic.sequence.count))").font(.subheadline).foregroundColor(.white.opacity(0.7))
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    let isHighlighted = logic.isShowingSequence && logic.currentShowIndex > 0 && logic.currentShowIndex <= logic.sequence.count && logic.sequence[logic.currentShowIndex - 1] == i
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorMap[i].opacity(isHighlighted ? 1.0 : 0.4))
                        .frame(height: 120)
                        .scaleEffect(isHighlighted ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                        .onTapGesture { logic.tapColor(i) }
                }
            }.padding(.horizontal, 32)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "brain.head.profile").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Game Over").font(.title.bold()).foregroundColor(.white)
            Text("Reached Round \(logic.round)").font(.headline).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.round > 5, score: logic.score, reward: reward) }
    }
}
