import SwiftUI
import Messages

struct BattleshipView: View {
    @State var state: BattleshipState
    var onMove: (String) -> Void

    var body: some View {
        VStack {
            Text("Battleship")
                .font(.headline)

            Text(state.isPlayer1Turn ? "Player 1's Turn" : "Player 2's Turn")
                .font(.subheadline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10)) {
                ForEach(0..<100) { index in
                    Rectangle()
                        .fill(colorFor(index))
                        .aspectRatio(1, contentMode: .fit)
                        .border(Color.gray)
                        .onTapGesture {
                            onMove("attack:\(index)")
                        }
                }
            }
            .padding()

            if !state.player1ShipsPlaced || !state.player2ShipsPlaced {
                Button("Place Ships Randomly") {
                    let randomIndices = (0..<5).map { _ in Int.random(in: 0..<100) }
                    onMove("place:\(randomIndices.map(String.init).joined(separator: ","))")
                }
                .padding()
            }
        }
    }

    private func colorFor(_ index: Int) -> Color {
        let board = state.isPlayer1Turn ? state.player2Board : state.player1Board
        switch board[index] {
        case 1: return .blue // hidden ship in real game, but showing for now
        case 2: return .red // hit
        case 3: return .white // miss
        default: return .cyan.opacity(0.3)
        }
    }
}
