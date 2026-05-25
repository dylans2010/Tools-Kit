import SwiftUI

struct TowerDefenseXView: View {
    @StateObject private var logic = TowerDefenseXLogic()
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Tower Defense X", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    HStack {
                        Text("❤️ \(logic.health)").foregroundColor(.red)
                        Spacer()
                        Text("💰 \(logic.gold)").foregroundColor(.yellow)
                    }
                    .padding()

                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 100))
                            path.addLine(to: CGPoint(x: 300, y: 100))
                            path.addLine(to: CGPoint(x: 300, y: 300))
                        }
                        .stroke(Color.gray, lineWidth: 40)

                        ForEach(logic.towers.indices, id: \.self) { i in
                            Circle().fill(Color.blue).frame(width: 30, height: 30)
                                .position(x: CGFloat(logic.towers[i].0), y: CGFloat(logic.towers[i].1))
                        }
                    }
                    .frame(height: 400)
                    .background(Color.black.opacity(0.3))
                    .onTapGesture { location in
                        logic.placeTower(at: (Int(location.x), Int(location.y)))
                    }

                    Text("Tap to place tower (50 💰)").font(.caption).foregroundColor(.secondary)

                    Button("Victory!") { gameState = .results }
                        .padding(.top)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
