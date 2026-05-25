import SwiftUI

struct ConnectFourBlitzView: View {
    @StateObject private var logic = ConnectFourBlitzLogic()
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
        .navigationTitle("Connect Four").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "circle.grid.3x3.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
            Text("Connect Four Blitz").font(.title.bold()).foregroundColor(.white)
            Text("Drop pieces to connect four in a row!\nPlay vs CPU.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Play") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack { Text("Wins: \(logic.wins)").foregroundColor(GamingDesignTokens.successGreen); Spacer(); Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }.padding(.horizontal)
            HStack(spacing: 2) {
                ForEach(0..<logic.cols, id: \.self) { c in
                    Button { logic.dropPiece(col: c) } label: {
                        VStack(spacing: 2) {
                            ForEach(0..<logic.rows, id: \.self) { r in
                                let val = r < logic.board.count && c < logic.board[r].count ? logic.board[r][c] : 0
                                Circle().fill(val == 1 ? GamingDesignTokens.accentNeon : (val == 2 ? GamingDesignTokens.dangerRed : Color.white.opacity(0.1)))
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(8).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

            if logic.gameOver {
                Text(logic.winner == 1 ? "You Win!" : (logic.winner == 2 ? "CPU Wins" : "Draw")).font(.title2.bold()).foregroundColor(logic.winner == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                HStack(spacing: 16) {
                    Button("Next") { logic.newRound() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("End") { logic.endSession() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 10).background(Color.white.opacity(0.15), in: Capsule())
                }
            }
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Text("Session Over").font(.title.bold()).foregroundColor(.white)
            Text("Wins: \(logic.wins)/\(logic.games)").foregroundColor(GamingDesignTokens.accentNeon)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.wins > 0, score: logic.score, reward: reward) }
    }
}
