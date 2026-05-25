import SwiftUI

struct TacticalRaidView: View {
    @StateObject private var logic = TacticalRaidLogic()
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Tactical Raid", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Text("Card Battle").font(.headline).foregroundColor(.white)
                    Spacer()
                    HStack {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 12).fill(Color.blue).frame(width: 80, height: 120)
                                .overlay(Text("Card \(i)"))
                        }
                    }
                    Spacer()
                    Button("Finish Raid") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 500, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
