import SwiftUI

struct ColorRushView: View {
    @StateObject private var logic = ColorRushLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    private let swiftColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]

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
        VStack(spacing: 24) {
            Image(systemName: "paintpalette.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Color Rush").font(.title.bold()).foregroundColor(.white)
            Text("Tap the COLOR the word is displayed in,\nnot the word itself! Stroop effect challenge.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 20) {
            HStack {
                Text(String(format: "%.1f", logic.timeRemaining) + "s").font(GamingDesignTokens.fontMono).foregroundColor(logic.timeRemaining < 5 ? GamingDesignTokens.dangerRed : .white)
                Spacer()
                Text("\(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)
            Text(logic.displayedWord).font(.system(size: 48, weight: .black))
                .foregroundColor(swiftColors[logic.displayedColorIndex])
            Text("Tap the COLOR of the text").font(.caption).foregroundColor(.white.opacity(0.5))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(logic.colorNames.enumerated()), id: \.offset) { idx, name in
                    Button { logic.selectColor(idx) } label: {
                        Text(name).font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(swiftColors[idx], in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 16)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Text("Time\'s Up!").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 50, score: logic.score, reward: reward) }
    }
}
