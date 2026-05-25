import SwiftUI

struct TicTacToeProView: View {
    @StateObject private var logic = TicTacToeProLogic()
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
        .navigationTitle("Tic Tac Toe Pro").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.circle").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Tic Tac Toe Pro").font(.title.bold()).foregroundColor(.white)
            Text("Classic X and O vs smart AI.").font(.subheadline).foregroundColor(.white.opacity(0.7))
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Play") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HStack { Text("Wins: \(logic.wins)").foregroundColor(GamingDesignTokens.successGreen); Spacer(); Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }.padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    Button { logic.makeMove(i) } label: {
                        Text(logic.board[i]).font(.system(size: 40, weight: .bold)).foregroundColor(logic.board[i] == "X" ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed)
                            .frame(maxWidth: .infinity).frame(height: 80).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 24)
            if logic.gameOver {
                Text(logic.result).font(.title2.bold()).foregroundColor(GamingDesignTokens.accentGold)
                HStack(spacing: 16) {
                    Button("Next Round") { logic.newRound() }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentNeon, in: Capsule())
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
