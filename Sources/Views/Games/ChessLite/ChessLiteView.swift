import SwiftUI

struct ChessLiteView: View {
    @StateObject private var logic = ChessLiteLogic()
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
        .navigationTitle("Chess Lite").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "crown.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Chess Lite").font(.title.bold()).foregroundColor(.white)
            Text("Play chess vs AI.\nCapture the king to win!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Play Chess") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 6) {
            HStack { Text(logic.currentPlayer == 1 ? "Your Turn" : "AI...").foregroundColor(.white); Spacer(); Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }.padding(.horizontal)
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { c in
                            let isLight = (r + c) % 2 == 0
                            let isSelected = logic.selectedPos?.row == r && logic.selectedPos?.col == c
                            let isValid = logic.validMoves.contains(where: { $0.row == r && $0.col == c })
                            ZStack {
                                Rectangle().fill(isLight ? Color.white.opacity(0.2) : Color.brown.opacity(0.4))
                                if isValid { Circle().fill(GamingDesignTokens.accentNeon.opacity(0.4)).frame(width: 16) }
                                if let piece = logic.board[r][c] { Text(piece.symbol).font(.system(size: 28)) }
                            }
                            .frame(width: 42, height: 42)
                            .border(isSelected ? GamingDesignTokens.accentGold : Color.clear, width: 2)
                            .onTapGesture { logic.selectCell(row: r, col: c) }
                        }
                    }
                }
            }
            HStack {
                Text("Captured: ").font(.caption).foregroundColor(.white.opacity(0.5))
                Text(logic.capturedByPlayer.map { $0.symbol }.joined()).font(.caption)
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            let won = logic.winner == 1
            Image(systemName: won ? "crown.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(won ? "Checkmate!" : "Defeated").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.winner == 1, score: logic.score, reward: reward) }
    }
}
