import SwiftUI

struct BlackjackProView: View {
    @StateObject private var logic = BlackjackProLogic()
    @State private var deck = CardDeckModel.newDeck()
    @State private var playerHand: [CardDeckModel.Card] = []
    @State private var dealerHand: [CardDeckModel.Card] = []
    @State private var gameState: GameState = .lobby
    @State private var bet = 50
    @State private var message = ""

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Blackjack Pro", gameID: logic.gameIdentifier) { startNewHand() }
            case .playing:
                VStack(spacing: 40) {
                    Text(message).foregroundColor(.gold).font(.headline)
                    handView(title: "Dealer (\(logic.score(dealerHand)))", hand: dealerHand, hideFirst: true)
                    handView(title: "Player (\(logic.score(playerHand)))", hand: playerHand, hideFirst: false)
                    HStack(spacing: 20) {
                        Button("HIT") { hit() }
                        Button("STAND") { stand() }
                        Button("DOUBLE") { doubleDown() }.disabled(playerHand.count > 2)
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: logic.score(playerHand) <= 21 && (logic.score(playerHand) > logic.score(dealerHand) || logic.score(dealerHand) > 21), score: bet * 2, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func handView(title: String, hand: [CardDeckModel.Card], hideFirst: Bool) -> some View {
        VStack {
            Text(title).foregroundColor(.secondary)
            HStack {
                ForEach(0..<hand.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8).fill(Color.white).frame(width: 60, height: 90)
                        .overlay(Text(hideFirst && i == 0 ? "?" : hand[i].display).foregroundColor(.black))
                }
            }
        }
    }

    private func startNewHand() {
        deck = CardDeckModel.newDeck()
        playerHand = [deck.removeLast(), deck.removeLast()]
        dealerHand = [deck.removeLast(), deck.removeLast()]
        message = ""
        gameState = .playing
    }

    private func hit() {
        playerHand.append(deck.removeLast())
        if logic.score(playerHand) > 21 {
            message = "BUST!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { gameState = .results }
        }
    }

    private func stand() {
        while logic.score(dealerHand) < 17 { dealerHand.append(deck.removeLast()) }
        gameState = .results
    }

    private func doubleDown() {
        try? CurrencyLedger.shared.spendCoins(bet)
        bet *= 2
        playerHand.append(deck.removeLast())
        stand()
    }
}
