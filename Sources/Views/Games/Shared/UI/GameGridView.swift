import SwiftUI

struct GameGridView: View {
    let games: [GameDefinition]
    let perGameStats: [String: GameStat]

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(games) { game in
                NavigationLink(destination: game.destination) {
                    GamingCardView(game: game, highScore: perGameStats[game.id]?.highScore ?? 0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}
