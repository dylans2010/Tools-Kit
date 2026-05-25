import SwiftUI

struct MemoryMatchView: View {
    @StateObject private var logic = MemoryMatchLogic()
    @State private var gameState: GameState = .lobby
    @State private var cards: [Card] = []
    @State private var flipped: [Int] = []
    @State private var matches = 0
    @State private var moves = 0

    struct Card: Identifiable {
        let id = UUID()
        let symbol: String
        var isFlipped = false
        var isMatched = false
    }

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Memory Match", gameID: logic.gameIdentifier) { start() }
            case .playing:
                VStack {
                    Text("Moves: \(moves)").foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(cards.indices, id: \.self) { i in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cards[i].isFlipped || cards[i].isMatched ? Color.white.opacity(0.1) : Color.purple)
                                if cards[i].isFlipped || cards[i].isMatched {
                                    Text(cards[i].symbol).font(.title)
                                }
                            }
                            .frame(height: 80)
                            .onTapGesture { tap(i) }
                        }
                    }
                }
                .padding()
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 1000 - moves * 10, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func start() {
        let symbols = ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓"]
        let pair = (symbols + symbols).shuffled()
        cards = pair.map { Card(symbol: $0) }
        flipped = []
        matches = 0
        moves = 0
        gameState = .playing
    }

    private func tap(_ i: Int) {
        guard !cards[i].isFlipped, !cards[i].isMatched, flipped.count < 2 else { return }
        cards[i].isFlipped = true
        flipped.append(i)
        if flipped.count == 2 {
            moves += 1
            if cards[flipped[0]].symbol == cards[flipped[1]].symbol {
                cards[flipped[0]].isMatched = true
                cards[flipped[1]].isMatched = true
                matches += 1
                flipped = []
                if matches == 8 { gameState = .results }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    cards[flipped[0]].isFlipped = false
                    cards[flipped[1]].isFlipped = false
                    flipped = []
                }
            }
        }
    }
}
