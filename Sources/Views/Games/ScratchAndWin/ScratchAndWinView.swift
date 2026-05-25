import SwiftUI

struct ScratchAndWinView: View {
    @StateObject private var logic = ScratchAndWinLogic()
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
        .navigationTitle("Scratch & Win").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Scratch & Win").font(.title.bold()).foregroundColor(.white)
            Text("Scratch to reveal symbols.\n3 matching = win! Cost: 50 coins per card.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Buy Card (50 coins)") { logic.buyCard() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            Text("Tap tiles to scratch!").font(.headline).foregroundColor(GamingDesignTokens.accentNeon)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(logic.tiles.enumerated()), id: \.offset) { idx, tile in
                    Button { withAnimation { logic.revealTile(idx) } } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(tile.revealed ? GamingDesignTokens.cardSurface : GamingDesignTokens.accentGold)
                            if tile.revealed { Image(systemName: tile.symbol.icon).font(.system(size: 32)).foregroundColor(.white) }
                            else { Image(systemName: "sparkle").font(.title).foregroundColor(.black.opacity(0.4)) }
                        }.frame(height: 90)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 32)
            Button("Reveal All") { logic.revealAll() }.font(.caption).foregroundColor(GamingDesignTokens.accentNeon)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: logic.lastWin > 0 ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(logic.lastWin > 0 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(logic.lastWin > 0 ? "Winner!" : "No Match").font(.title.bold()).foregroundColor(.white)
            if logic.lastWin > 0 { Text("+\(logic.lastWin) coins!").font(.title2.bold()).foregroundColor(GamingDesignTokens.accentGold) }
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Buy Another") { logic.buyCard() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.lastWin > 0, score: logic.score, reward: reward) }
    }
}
