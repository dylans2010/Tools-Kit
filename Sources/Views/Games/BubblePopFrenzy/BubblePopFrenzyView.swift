import SwiftUI

struct BubblePopFrenzyView: View {
    @StateObject private var logic = BubblePopFrenzyLogic()
    @ObservedObject var ledger = CurrencyLedger.shared
    @ObservedObject var xpEngine = XPEngine.shared
    @Environment(\.dismiss) private var dismiss

    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple]

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
        .navigationTitle("Bubble Pop").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var lobbyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Bubble Pop Frenzy").font(.title.bold()).foregroundColor(.white)
            Text("Pop as many bubbles as you can in 30 seconds!\nSame color combos multiply points!").font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
            HStack { Text("Best:").foregroundColor(.white.opacity(0.6)); Text("\(ledger.highScore(for: logic.gameIdentifier))").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold) }
            Button("Pop!") { logic.startGame() }.font(.headline).foregroundColor(.black).padding(.horizontal, 48).padding(.vertical, 14).background(GamingDesignTokens.accentGold, in: Capsule()).pulseAnimation()
        }.padding()
    }

    private var gameView: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    HStack {
                        Text(String(format: "%.1f", logic.timeRemaining) + "s").font(GamingDesignTokens.fontMono).foregroundColor(logic.timeRemaining < 5 ? GamingDesignTokens.dangerRed : .white)
                        Spacer()
                        if logic.combo > 1 { Text("x\(logic.combo) combo!").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple) }
                        Spacer()
                        Text("\(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold).contentTransition(.numericText())
                    }.padding(.horizontal)
                    Spacer()
                }
                ForEach(logic.bubbles.filter { !$0.popped }) { bubble in
                    Circle().fill(colors[bubble.color % colors.count].opacity(0.8))
                        .frame(width: bubble.size, height: bubble.size)
                        .position(x: bubble.x * geo.size.width, y: bubble.y * geo.size.height)
                        .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { logic.popBubble(bubble.id) } }
                        .transition(.scale)
                }
            }
        }
    }

    private var resultsView: some View {
        let reward = logic.finalReward()
        return VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 64)).foregroundColor(GamingDesignTokens.accentNeon)
            Text("Time\'s Up!").font(.title.bold()).foregroundColor(.white)
            Text("Score: \(logic.score)").font(GamingDesignTokens.fontMono).foregroundColor(GamingDesignTokens.accentGold)
            RewardToastView(reward: reward)
            HStack(spacing: 16) {
                Button("Play Again") { logic.phase = .lobby }.font(.headline).foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12).background(GamingDesignTokens.accentNeon, in: Capsule())
                Button("Back") { dismiss() }.font(.headline).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 12).background(Color.white.opacity(0.15), in: Capsule())
            }
        }.padding().onAppear { ledger.recordGame(identifier: logic.gameIdentifier, won: logic.score > 200, score: logic.score, reward: reward) }
    }
}
