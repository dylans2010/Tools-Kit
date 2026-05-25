import SwiftUI

struct GameGridView: View {
    let games: [GameDefinition]
    let ledger: CurrencyLedger
    let onSelect: (GameDefinition) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(games) { game in
                GamingCardView(
                    game: game,
                    highScore: ledger.highScore(for: game.id),
                    onTap: { onSelect(game) }
                )
            }
        }
    }
}
