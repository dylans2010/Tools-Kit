import SwiftUI

struct TapRaceView: View {
    @State var state: TapRaceState
    @State private var taps = 0
    @State private var timeLeft = 5.0
    @State private var isRacing = false

    var onMove: (String) -> Void
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap Race")
                .font(.largeTitle)

            if state.isFinished {
                VStack {
                    Text("Result")
                        .font(.headline)
                    Text("P1: \(state.player1Taps) vs P2: \(state.player2Taps)")
                    Text(state.player1Taps > state.player2Taps ? "Player 1 Wins!" : "Player 2 Wins!")
                        .font(.title)
                        .foregroundColor(.green)
                }
            } else if isRacing {
                VStack {
                    Text("TAPS: \(taps)")
                        .font(.system(size: 60, weight: .bold))
                    Text(String(format: "Time Left: %.1f", timeLeft))
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .onReceive(timer) { _ in
                    if timeLeft > 0 {
                        timeLeft -= 0.1
                    } else {
                        isRacing = false
                        onMove("finish:\(taps)")
                    }
                }
                .onTapGesture {
                    taps += 1
                }
            } else {
                Text(state.isPlayer1Turn ? "Player 1's Turn" : "Player 2's Turn")
                    .font(.headline)

                Button("Start Race!") {
                    taps = 0
                    timeLeft = 5.0
                    isRacing = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
    }
}
