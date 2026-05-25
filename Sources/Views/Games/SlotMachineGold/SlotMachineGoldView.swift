import SwiftUI

struct SlotMachineGoldView: View {
    @StateObject private var logic = SlotMachineGoldLogic()
    @State private var reels = ["🍒", "🍒", "🍒"]
    @State private var bet = 10
    @State private var balance = CurrencyLedger.shared.profile.coins
    @State private var gameState: GameState = .lobby
    @State private var lastWin = 0

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Slot Machine Gold", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack(spacing: 30) {
                    Text("Slots Gold").font(.title.bold()).foregroundColor(.white)
                    Text("Balance: \(balance) 💰").foregroundColor(.secondary)

                    HStack(spacing: 20) {
                        SlotReelView(currentSymbol: $reels[0])
                        SlotReelView(currentSymbol: $reels[1])
                        SlotReelView(currentSymbol: $reels[2])
                    }

                    HStack {
                        Button("-") { if bet > 10 { bet -= 10 } }
                        Text("Bet: \(bet)").bold().foregroundColor(.white).padding(.horizontal)
                        Button("+") { if bet < balance { bet += 10 } }
                    }

                    Button("SPIN") { spin() }
                        .disabled(balance < bet)
                        .buttonStyle(.borderedProminent)

                    Button("CASH OUT") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: lastWin > 0, score: lastWin, streakMultiplier: 1.0)) {
                    gameState = .lobby
                    balance = CurrencyLedger.shared.profile.coins
                }
            }
        }
    }

    private func spin() {
        try? CurrencyLedger.shared.spendCoins(bet)
        balance -= bet
        let symbols = ["🍒", "🍋", "🔔", "⭐", "7️⃣"]
        reels = reels.map { _ in symbols.randomElement()! }

        if reels[0] == reels[1] && reels[1] == reels[2] {
            lastWin = bet * 10
        } else if reels[0] == reels[1] || reels[1] == reels[2] || reels[0] == reels[2] {
            lastWin = bet * 2
        } else {
            lastWin = 0
        }
        if lastWin > 0 {
            CurrencyLedger.shared.awardCoins(lastWin, reason: "Slot Win")
            balance += lastWin
        }
    }
}
