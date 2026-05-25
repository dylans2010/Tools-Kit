import SwiftUI

struct CheckersArenaView: View {
    @StateObject private var logic = CheckersArenaLogic()
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
        .navigationTitle("Checkers Arena").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "circle.grid.cross").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Checkers Arena").font(.title.bold()).foregroundColor(.white)
            Text("Classic checkers vs AI.\nJump to capture, reach the end to be king!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Play") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack { Text(logic.currentPlayer == 1 ? "Your Turn" : "AI Thinking...").foregroundColor(.white); Spacer(); Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }.padding(.horizontal)
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { c in
                            let isDark = (r + c) % 2 == 1
                            let isSelected = logic.selectedPos?.row == r && logic.selectedPos?.col == c
                            let isValid = logic.validMoves.contains(where: { $0.row == r && $0.col == c })
                            ZStack {
                                Rectangle().fill(isDark ? Color.brown.opacity(0.6) : Color.brown.opacity(0.2))
                                if isValid { Circle().fill(GamingDesignTokens.accentNeon.opacity(0.3)).frame(width: 20) }
                                if let piece = logic.board[r][c] {
                                    Circle().fill(piece.player == 1 ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed)
                                        .frame(width: 32, height: 32)
                                        .overlay(piece.isKing ? Image(systemName: "crown.fill").font(.caption2).foregroundColor(.white) : nil)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .border(isSelected ? GamingDesignTokens.accentGold : Color.clear, width: 2)
                            .onTapGesture { logic.selectCell(row: r, col: c) }
                        }
                    }
                }
            }.padding(.horizontal)
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            let won = logic.winner == 1
            Image(systemName: won ? "trophy.fill" : "xmark.circle.fill").font(.system(size: 64)).foregroundColor(won ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            Text(won ? "You Win!" : "AI Wins").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.winner == 1, score: logic.score, reward: reward) }
    }
}
