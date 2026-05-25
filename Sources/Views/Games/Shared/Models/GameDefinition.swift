import Foundation

struct GameDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let category: GameCategory
    let icon: String
    let accentColorHex: String
    let shortDescription: String

    static let allGames: [GameDefinition] = [
        GameDefinition(id: "battlefield_commander", title: "Battlefield Commander", category: .warBattle, icon: "shield.lefthalf.filled", accentColorHex: "#FF6B35", shortDescription: "Turn-based grid tactics"),
        GameDefinition(id: "warzone_strike", title: "WarZone Strike", category: .warBattle, icon: "scope", accentColorHex: "#E63946", shortDescription: "Tap-to-shoot wave survival"),
        GameDefinition(id: "tactical_raid", title: "Tactical Raid", category: .warBattle, icon: "bolt.shield.fill", accentColorHex: "#D62828", shortDescription: "1v1 card battle"),

        GameDefinition(id: "memory_match", title: "Memory Match", category: .memoryBrain, icon: "square.grid.3x3.fill", accentColorHex: "#8338EC", shortDescription: "Classic card flip memory"),
        GameDefinition(id: "sequence_recall", title: "Sequence Recall", category: .memoryBrain, icon: "waveform.path.ecg", accentColorHex: "#7209B7", shortDescription: "Simon-style sequence game"),
        GameDefinition(id: "number_vault", title: "Number Vault", category: .memoryBrain, icon: "number.square.fill", accentColorHex: "#560BAD", shortDescription: "Memorize number grids"),

        GameDefinition(id: "slot_machine_gold", title: "Slot Machine Gold", category: .casinoGambling, icon: "dollarsign.circle.fill", accentColorHex: "#FFD700", shortDescription: "3-reel slot machine"),
        GameDefinition(id: "blackjack_pro", title: "Blackjack Pro", category: .casinoGambling, icon: "suit.spade.fill", accentColorHex: "#2D6A4F", shortDescription: "Full blackjack"),
        GameDefinition(id: "poker_nights", title: "Poker Nights", category: .casinoGambling, icon: "suit.diamond.fill", accentColorHex: "#B5179E", shortDescription: "5-card draw poker"),
        GameDefinition(id: "roulette_royal", title: "Roulette Royal", category: .casinoGambling, icon: "circle.hexagongrid.fill", accentColorHex: "#C9184A", shortDescription: "European roulette"),
        GameDefinition(id: "dice_roll_fortune", title: "Dice Roll Fortune", category: .casinoGambling, icon: "dice.fill", accentColorHex: "#FF9F1C", shortDescription: "Dice combination payouts"),
        GameDefinition(id: "scratch_and_win", title: "Scratch & Win", category: .casinoGambling, icon: "sparkles.rectangle.stack", accentColorHex: "#FFBE0B", shortDescription: "Scratch card reveals"),

        GameDefinition(id: "word_storm", title: "Word Storm", category: .puzzleLogic, icon: "textformat.abc", accentColorHex: "#06D6A0", shortDescription: "Anagram solver"),
        GameDefinition(id: "trivia_crush", title: "Trivia Crush", category: .puzzleLogic, icon: "questionmark.circle.fill", accentColorHex: "#118AB2", shortDescription: "Multiple choice trivia"),
        GameDefinition(id: "math_blitz", title: "Math Blitz", category: .puzzleLogic, icon: "function", accentColorHex: "#073B4C", shortDescription: "Rapid-fire arithmetic"),
        GameDefinition(id: "sudoku_master", title: "Sudoku Master", category: .puzzleLogic, icon: "square.grid.3x3.topleft.filled", accentColorHex: "#3A86FF", shortDescription: "Classic Sudoku puzzles"),
        GameDefinition(id: "minesweeper_x", title: "Minesweeper X", category: .puzzleLogic, icon: "circle.grid.cross.fill", accentColorHex: "#457B9D", shortDescription: "Classic Minesweeper"),

        GameDefinition(id: "snake_ladder_classic", title: "Snake & Ladder", category: .boardClassic, icon: "arrow.up.right.and.arrow.down.left.rectangle.fill", accentColorHex: "#E76F51", shortDescription: "Classic board game"),
        GameDefinition(id: "chess_lite", title: "Chess Lite", category: .boardClassic, icon: "crown.fill", accentColorHex: "#264653", shortDescription: "Full chess with AI"),
        GameDefinition(id: "checkers_arena", title: "Checkers Arena", category: .boardClassic, icon: "circle.grid.2x2.fill", accentColorHex: "#E9C46A", shortDescription: "Standard checkers"),
        GameDefinition(id: "tictactoe_pro", title: "Tic Tac Toe Pro", category: .boardClassic, icon: "number", accentColorHex: "#2A9D8F", shortDescription: "3x3 and 5x5 variants"),
        GameDefinition(id: "connect_four_blitz", title: "Connect Four Blitz", category: .boardClassic, icon: "circle.grid.3x3.fill", accentColorHex: "#F4A261", shortDescription: "Connect Four with AI"),

        GameDefinition(id: "bubble_pop_frenzy", title: "Bubble Pop Frenzy", category: .arcadeReflex, icon: "bubble.right.fill", accentColorHex: "#FF006E", shortDescription: "Pop rising bubbles"),
        GameDefinition(id: "tower_defense_x", title: "Tower Defense X", category: .arcadeReflex, icon: "building.columns.fill", accentColorHex: "#8AC926", shortDescription: "Strategic tower defense"),
        GameDefinition(id: "asteroid_dodge", title: "Asteroid Dodge", category: .arcadeReflex, icon: "star.leadinghalf.filled", accentColorHex: "#6A4C93", shortDescription: "Dodge incoming asteroids"),
        GameDefinition(id: "color_rush", title: "Color Rush", category: .arcadeReflex, icon: "paintpalette.fill", accentColorHex: "#1982C4", shortDescription: "Match falling color tiles"),
        GameDefinition(id: "reaction_tap", title: "Reaction Tap", category: .arcadeReflex, icon: "hand.tap.fill", accentColorHex: "#FFCA3A", shortDescription: "Test reaction speed"),

        GameDefinition(id: "spin_wheel_prize", title: "Spin Wheel Prize", category: .spinLuck, icon: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill", accentColorHex: "#FF595E", shortDescription: "Prize wheel spins"),
        GameDefinition(id: "flip_card_duel", title: "Flip Card Duel", category: .spinLuck, icon: "rectangle.portrait.on.rectangle.portrait.fill", accentColorHex: "#6A0572", shortDescription: "High card duel betting"),
    ]

    static func game(for identifier: String) -> GameDefinition? {
        allGames.first { $0.id == identifier }
    }

    static func games(in category: GameCategory) -> [GameDefinition] {
        allGames.filter { $0.category == category }
    }

    static func featuredGame(for date: Date = Date()) -> GameDefinition {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % allGames.count
        return allGames[index]
    }
}
