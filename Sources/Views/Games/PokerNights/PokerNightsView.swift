import SwiftUI

struct PokerNightsView: View {
    @StateObject private var logic = PokerNightsLogic()
    @State private var hand: [CardDeckModel.Card] = []
    @State private var gameState: GameState = .lobby
    @State private var pot = 200

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Poker Nights", gameID: logic.gameIdentifier) { startRound() }
            case .playing:
                VStack(spacing: 40) {
                    Text("Pot: \(pot) 💰").foregroundColor(.yellow)
                    HStack {
                        ForEach(0..<hand.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 8).fill(Color.white).frame(width: 60, height: 90)
                                .overlay(Text(hand[i].display).foregroundColor(.black))
                        }
                    }
                    Button("SHOWDOWN") { gameState = .results }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: pot, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func startRound() {
        var deck = CardDeckModel.newDeck()
        hand = (0..<5).map { _ in deck.removeLast() }
        gameState = .playing
    }
}
