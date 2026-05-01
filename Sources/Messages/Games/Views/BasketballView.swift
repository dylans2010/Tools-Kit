import SwiftUI

struct BasketballView: View {
    @State var state: BasketballState
    var onMove: (String) -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Basketball")
                .font(.largeTitle)

            HStack {
                VStack {
                    Text("P1 Score")
                    Text("\(state.player1Score)")
                        .font(.title)
                }
                Spacer()
                VStack {
                    Text("P2 Score")
                    Text("\(state.player2Score)")
                        .font(.title)
                }
            }
            .padding(.horizontal, 50)

            ZStack {
                Circle()
                    .stroke(Color.orange, lineWidth: 4)
                    .frame(width: 200, height: 200)

                Text("🏀")
                    .font(.system(size: 80))
            }
            .onTapGesture {
                let success = Bool.random()
                onMove("shoot:\(success ? "success" : "fail")")
            }

            Text(state.isPlayer1Turn ? "Player 1's Turn" : "Player 2's Turn")
                .font(.headline)

            Text("Tap the ball to shoot!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
