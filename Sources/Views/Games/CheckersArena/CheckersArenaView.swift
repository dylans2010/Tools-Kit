import SwiftUI

struct CheckersArenaView: View {
    @StateObject private var logic = CheckersArenaLogic()
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
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
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "circle.grid.cross.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.dangerRed)
                Text("Checkers Arena").font(.title.bold()).foregroundColor(.white)
                Text("Classic checkers with multi-jump captures.\n3 AI difficulty levels.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                let stats = ledger.gameStats(for: logic.gameIdentifier)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Level \(stats.gameLevel)").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
                        ProgressView(value: Double(stats.gameXP % 100), total: 100).tint(GamingDesignTokens.accentNeon)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Games: \(stats.gamesPlayed)").font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("Wins: \(stats.wins)").font(.caption2).foregroundColor(GamingDesignTokens.successGreen)
                    }
                }.padding(10).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))

                HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }

                VStack(spacing: 12) {
                    ForEach(Array(["Easy", "Medium", "Hard"].enumerated()), id: \.offset) { idx, label in
                        Button("\(label) Match") { logic.startGame(difficulty: idx) }
                            .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(idx == 0 ? GamingDesignTokens.accentNeon : (idx == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed), in: Capsule())
                    }
                }.padding(.horizontal, 32)

                if ledger.canClaimDailyBonus(for: logic.gameIdentifier) {
                    Button { ledger.claimDailyBonus(for: logic.gameIdentifier) } label: {
                        Label("Claim Daily Bonus", systemImage: "gift.fill").font(.subheadline.bold()).foregroundColor(.black)
                            .padding(.horizontal, 24).padding(.vertical, 10).background(GamingDesignTokens.accentGold, in: Capsule())
                    }
                }
            }.padding()
        }
    }

    private var gameView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(logic.currentPlayer == 1 ? "Your Turn" : "AI Turn").font(.caption.bold())
                    .foregroundColor(logic.currentPlayer == 1 ? GamingDesignTokens.accentNeon : GamingDesignTokens.dangerRed)
                Spacer()
                Text("Captures: \(logic.captureCount)").font(.caption2).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
            }.padding(.horizontal)

            GeometryReader { geo in
                let cellSize = min(geo.size.width, geo.size.height) / 8
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { col in
                                checkerCell(row: row, col: col, size: cellSize)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func checkerCell(row: Int, col: Int, size: CGFloat) -> some View {
        let piece = row < logic.board.count && col < logic.board[row].count ? logic.board[row][col] : 0
        let isSelected = logic.selectedPiece?.row == row && logic.selectedPiece?.col == col
        return ZStack {
            Rectangle().fill((row + col) % 2 == 0 ? Color.white.opacity(0.08) : Color.brown.opacity(0.3))
                .border(isSelected ? GamingDesignTokens.accentNeon : Color.clear, width: isSelected ? 2 : 0)
            if piece == 1 || piece == 3 {
                Circle().fill(GamingDesignTokens.accentNeon).frame(width: size * 0.7, height: size * 0.7)
                    .overlay { if piece == 3 { Image(systemName: "crown.fill").font(.system(size: size * 0.25)).foregroundColor(.white) } }
            } else if piece == 2 || piece == 4 {
                Circle().fill(GamingDesignTokens.dangerRed).frame(width: size * 0.7, height: size * 0.7)
                    .overlay { if piece == 4 { Image(systemName: "crown.fill").font(.system(size: size * 0.25)).foregroundColor(.white) } }
            }
        }
        .frame(width: size, height: size)
        .onTapGesture { logic.tapCell(row: row, col: col) }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: logic.winner == 1 ? "trophy.fill" : "xmark.octagon.fill").font(.system(size: 64))
                    .foregroundColor(logic.winner == 1 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
                Text(logic.winner == 1 ? "Victory!" : "Defeated").font(.title.bold()).foregroundColor(.white)

                VStack(spacing: 8) {
                    statRow("Score", "\(logic.score)")
                    statRow("Captures", "\(logic.captureCount)")
                    statRow("Kings Promoted", "\(logic.kingsPromoted)")
                    statRow("Moves", "\(logic.moveCount)")
                    statRow("Streak Multiplier", String(format: "%.1fx", logic.streakMultiplier))
                }.padding(12).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))

                RewardToastView(reward: reward)
                if let badge = reward.badgeUnlocked {
                    Label(badge, systemImage: "star.fill").font(.headline).foregroundColor(GamingDesignTokens.accentGold).padding(8).background(GamingDesignTokens.cardSurface, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                    Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding()
        }.onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.winner == 1, score: logic.score, reward: reward) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.bold()).foregroundColor(.white) }
    }
}
