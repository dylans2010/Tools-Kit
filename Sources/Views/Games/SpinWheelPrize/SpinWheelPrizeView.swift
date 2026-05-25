import SwiftUI

struct SpinWheelPrizeView: View {
    @StateObject private var logic = SpinWheelPrizeLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    private let wheelColors: [Color] = [.red, .blue, .green, .orange, .purple, .yellow]

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
        .navigationTitle("Spin Wheel").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentGold)
            Text("Spin Wheel Prize").font(.title.bold()).foregroundColor(.white)
            Text("Spin the wheel to win coins!\n25 coins per spin.").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Start") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            HUDOverlayView(ledger: ledger, xpEngine: xpEngine)
            ZStack {
                Circle().fill(GamingDesignTokens.cardSurface).frame(width: 250, height: 250)
                ForEach(Array(logic.slices.enumerated()), id: \.element.id) { idx, slice in
                    let angle = Double(idx) * (360.0 / Double(logic.slices.count))
                    Text(slice.label).font(.caption.bold()).foregroundColor(.white)
                        .offset(y: -90).rotationEffect(.degrees(angle))
                }
            }.rotationEffect(.degrees(logic.rotation))
            .animation(.easeOut(duration: 3.0), value: logic.rotation)

            Image(systemName: "arrowtriangle.down.fill").font(.title).foregroundColor(GamingDesignTokens.dangerRed)

            if let result = logic.resultSlice {
                Text(result.prize > 0 ? "+\(result.prize) coins!" : "No prize").font(.title2.bold()).foregroundColor(result.prize > 0 ? GamingDesignTokens.accentGold : GamingDesignTokens.dangerRed)
            }
            Button(logic.isSpinning ? "Spinning..." : "Spin (25c)") { logic.spin() }.font(.title2.bold()).foregroundColor(.black).padding(.horizontal, 50).padding(.vertical, 14)
                .background(logic.isSpinning ? Color.gray : GamingDesignTokens.accentGold, in: Capsule()).disabled(logic.isSpinning)
            Button("End") { logic.endSession() }.font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Text("Session Over").font(.title.bold()).foregroundColor(.white)
            Text("Spins: \(logic.spins) | Won: \(logic.totalWon)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.totalWon > 0, score: logic.score, reward: reward) }
    }
}
