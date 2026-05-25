import SwiftUI

struct FlipCardDuelView: View {
    @StateObject private var logic = FlipCardDuelLogic()
    @State private var playerCard: CardDeckModel.Card?
    @State private var opponentCard: CardDeckModel.Card?
    @State private var gameState: GameState = .lobby
    @State private var bet = 50

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Flip Card Duel", gameID: logic.gameIdentifier) { flip() }
            case .playing:
                VStack(spacing: 40) {
                    HStack(spacing: 40) {
                        cardView(title: "Opponent", card: opponentCard)
                        cardView(title: "Player", card: playerCard)
                    }
                    Button("RESULTS") { gameState = .results }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                let won = (playerCard?.rank.value ?? 0) > (opponentCard?.rank.value ?? 0)
                ResultsView(reward: logic.calculateFinalReward(won: won, score: won ? bet * 2 : 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func cardView(title: String, card: CardDeckModel.Card?) -> some View {
        VStack {
            Text(title).foregroundColor(.secondary)
            RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(width: 100, height: 150)
                .overlay(Text(card?.display ?? "?").font(.largeTitle).foregroundColor(.black))
        }
    }

    private func flip() {
        var deck = CardDeckModel.newDeck()
        playerCard = deck.removeLast()
        opponentCard = deck.removeLast()
        gameState = .playing
    }
}
