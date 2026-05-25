import SwiftUI

struct NumberVaultView: View {
    @StateObject private var logic = NumberVaultLogic()
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
        .navigationTitle("Number Vault").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "number.square.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentPurple)
            Text("Number Vault").font(.title.bold()).foregroundColor(.white)
            Text("Memorize the grid of numbers,\nthen reproduce them from memory.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            VStack(spacing: 12) {
                ForEach(Array(["3×3 Easy", "4×4 Medium", "5×5 Hard"].enumerated()), id: \.offset) { idx, label in
                    Button(label) { logic.startGame(difficulty: idx) }.font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                }
            }.padding(.horizontal, 32)
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            Text(logic.isMemorizing ? "Memorize!" : "Reproduce the numbers").font(.headline).foregroundColor(logic.isMemorizing ? GamingDesignTokens.accentGold : GamingDesignTokens.accentNeon)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: logic.gridSize), spacing: 8) {
                ForEach(0..<logic.gridSize, id: \.self) { r in
                    ForEach(0..<logic.gridSize, id: \.self) { c in
                        cellView(row: r, col: c)
                    }
                }
            }.padding(.horizontal, 24)
            if !logic.isMemorizing {
                numberPad
                Button("Submit") { logic.submitGrid() }.font(.headline).foregroundColor(.black).padding(.horizontal, 40).padding(.vertical, 12).background(GamingDesignTokens.accentGold, in: Capsule())
            }
            Spacer()
        }
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isSelected = logic.selectedCell?.row == row && logic.selectedCell?.col == col
        return ZStack {
            RoundedRectangle(cornerRadius: 8).fill(isSelected ? GamingDesignTokens.accentNeon.opacity(0.2) : GamingDesignTokens.cardSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? GamingDesignTokens.accentNeon : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1))
            if logic.isMemorizing {
                Text("\(logic.grid[row][col])").font(.title.bold().monospacedDigit()).foregroundColor(.white)
            } else {
                Text(logic.playerGrid[row][col].map { "\($0)" } ?? "").font(.title.bold().monospacedDigit()).foregroundColor(GamingDesignTokens.accentNeon)
            }
        }.frame(height: 60).onTapGesture { logic.selectedCell = (row, col) }
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
            ForEach(1...9, id: \.self) { n in
                Button("\(n)") {
                    if let sel = logic.selectedCell { logic.inputNumber(n, row: sel.row, col: sel.col) }
                }.font(.headline).foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity).background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 8))
            }
        }.padding(.horizontal, 24)
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.successGreen)
            Text("Results").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: true, score: logic.score, reward: reward) }
    }
}
