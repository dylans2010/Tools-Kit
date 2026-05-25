import SwiftUI

struct MemoryMatchView: View {
    @StateObject private var logic = MemoryMatchLogic()
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
        .navigationTitle("Memory Match").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.3x3.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Memory Match").font(.title.bold()).foregroundColor(.white)
            Text("Flip cards to find matching pairs.\nChoose difficulty and mode.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            VStack(spacing: 12) {
                ForEach(Array(["4×4 Easy", "5×4 Medium", "6×5 Hard"].enumerated()), id: \.offset) { idx, label in
                    Button(label) { logic.startGame(difficulty: idx, timerMode: false) }
                        .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(GamingDesignTokens.accentNeon, in: Capsule())
                }
            }.padding(.horizontal, 32)
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Moves: \(logic.moves)").font(.caption.bold()).foregroundColor(.white)
                Spacer()
                Text("Matched: \(logic.matchesFound)/\(logic.totalPairs)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            let cols = logic.difficulty == 0 ? 4 : (logic.difficulty == 1 ? 4 : 5)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                ForEach(Array(logic.cards.enumerated()), id: \.element.id) { idx, card in
                    cardCell(card, index: idx)
                }
            }.padding(.horizontal, 8)
            Spacer()
        }
    }

    private func cardCell(_ card: MemoryCard, index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.3)) { logic.flipCard(at: index) } } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.isMatched ? GamingDesignTokens.successGreen.opacity(0.3) : (card.isFaceUp ? GamingDesignTokens.accentPurple.opacity(0.3) : GamingDesignTokens.cardSurface))
                if card.isFaceUp || card.isMatched {
                    Image(systemName: card.symbol).font(.title2).foregroundColor(.white)
                } else {
                    Image(systemName: "questionmark").font(.title3).foregroundColor(.white.opacity(0.3))
                }
            }.frame(height: 60)
        }.buttonStyle(.plain).disabled(card.isFaceUp || card.isMatched)
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "trophy.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Complete!").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score) | Moves: \(logic.moves)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: true, score: logic.score, reward: reward) }
    }
}
