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

        GameDefinition(id: "tank_assault", title: "Tank Assault", category: .warBattle, icon: "truck.box.fill", accentColorHex: "#C75000", shortDescription: "Command a tank through enemy waves"),
        GameDefinition(id: "air_strike_force", title: "Air Strike Force", category: .warBattle, icon: "airplane", accentColorHex: "#4A90D9", shortDescription: "Shoot down enemy aircraft"),
        GameDefinition(id: "naval_combat", title: "Naval Combat", category: .warBattle, icon: "ferry.fill", accentColorHex: "#1B4F72", shortDescription: "Sink the enemy fleet"),
        GameDefinition(id: "zombie_siege", title: "Zombie Siege", category: .warBattle, icon: "figure.walk", accentColorHex: "#4A752C", shortDescription: "Survive zombie hordes"),
        GameDefinition(id: "missile_launch", title: "Missile Launch", category: .warBattle, icon: "location.north.fill", accentColorHex: "#FF4444", shortDescription: "Intercept incoming missiles"),
        GameDefinition(id: "duel_arena", title: "Duel Arena", category: .warBattle, icon: "person.2.fill", accentColorHex: "#8B4513", shortDescription: "1v1 western quickdraw"),
        GameDefinition(id: "fortress_defend", title: "Fortress Defend", category: .warBattle, icon: "building.fill", accentColorHex: "#5D4E37", shortDescription: "Defend your fortress walls"),
        GameDefinition(id: "space_invader", title: "Space Invader", category: .warBattle, icon: "sparkle", accentColorHex: "#6A0DAD", shortDescription: "Classic space shooter"),

        GameDefinition(id: "pattern_pulse", title: "Pattern Pulse", category: .memoryBrain, icon: "waveform.circle.fill", accentColorHex: "#9B59B6", shortDescription: "Repeat growing patterns"),
        GameDefinition(id: "color_memory", title: "Color Memory", category: .memoryBrain, icon: "circle.fill", accentColorHex: "#E74C3C", shortDescription: "Remember color sequences"),
        GameDefinition(id: "sound_match", title: "Sound Match", category: .memoryBrain, icon: "speaker.wave.2.fill", accentColorHex: "#3498DB", shortDescription: "Match pairs of sounds"),
        GameDefinition(id: "speed_read", title: "Speed Read", category: .memoryBrain, icon: "book.fill", accentColorHex: "#27AE60", shortDescription: "Read and recall fast"),
        GameDefinition(id: "face_recall", title: "Face Recall", category: .memoryBrain, icon: "person.crop.circle", accentColorHex: "#F39C12", shortDescription: "Remember shown faces"),
        GameDefinition(id: "maze_runner", title: "Maze Runner", category: .memoryBrain, icon: "square.grid.3x3.middle.filled", accentColorHex: "#1ABC9C", shortDescription: "Navigate memory mazes"),
        GameDefinition(id: "digit_dash", title: "Digit Dash", category: .memoryBrain, icon: "textformat.123", accentColorHex: "#E67E22", shortDescription: "Quick digit recall"),
        GameDefinition(id: "symbol_snap", title: "Symbol Snap", category: .memoryBrain, icon: "star.square.fill", accentColorHex: "#8E44AD", shortDescription: "Match symbols quickly"),

        GameDefinition(id: "baccarat_elite", title: "Baccarat Elite", category: .casinoGambling, icon: "suit.heart.fill", accentColorHex: "#C0392B", shortDescription: "Classic baccarat card game"),
        GameDefinition(id: "craps_king", title: "Craps King", category: .casinoGambling, icon: "die.face.5.fill", accentColorHex: "#D4AC0D", shortDescription: "Roll the dice craps style"),
        GameDefinition(id: "keno_blast", title: "Keno Blast", category: .casinoGambling, icon: "circle.grid.3x3", accentColorHex: "#2ECC71", shortDescription: "Pick numbers keno lottery"),
        GameDefinition(id: "video_poker_pro", title: "Video Poker Pro", category: .casinoGambling, icon: "rectangle.stack.fill", accentColorHex: "#9B59B6", shortDescription: "5-card video poker machine"),
        GameDefinition(id: "high_low_battle", title: "High Low Battle", category: .casinoGambling, icon: "arrow.up.arrow.down", accentColorHex: "#F1C40F", shortDescription: "Guess higher or lower"),
        GameDefinition(id: "lottery_draw", title: "Lottery Draw", category: .casinoGambling, icon: "ticket.fill", accentColorHex: "#E74C3C", shortDescription: "Pick lucky lottery numbers"),
        GameDefinition(id: "coin_flip_duel", title: "Coin Flip Duel", category: .casinoGambling, icon: "bitcoinsign.circle.fill", accentColorHex: "#F39C12", shortDescription: "Double or nothing coin flip"),
        GameDefinition(id: "wheel_of_riches", title: "Wheel of Riches", category: .casinoGambling, icon: "figure.roll", accentColorHex: "#8E44AD", shortDescription: "Spin the mega wheel"),

        GameDefinition(id: "crossword_mini", title: "Crossword Mini", category: .puzzleLogic, icon: "rectangle.split.3x3", accentColorHex: "#2980B9", shortDescription: "Mini crossword puzzles"),
        GameDefinition(id: "logic_gates", title: "Logic Gates", category: .puzzleLogic, icon: "cpu", accentColorHex: "#34495E", shortDescription: "Solve logic circuits"),
        GameDefinition(id: "pipe_connect", title: "Pipe Connect", category: .puzzleLogic, icon: "arrow.triangle.branch", accentColorHex: "#16A085", shortDescription: "Connect pipes to flow"),
        GameDefinition(id: "tower_of_hanoi", title: "Tower of Hanoi", category: .puzzleLogic, icon: "square.3.layers.3d", accentColorHex: "#D35400", shortDescription: "Classic disc puzzle"),
        GameDefinition(id: "lights_out", title: "Lights Out", category: .puzzleLogic, icon: "lightbulb.fill", accentColorHex: "#F1C40F", shortDescription: "Toggle all lights off"),
        GameDefinition(id: "slide_puzzle", title: "Slide Puzzle", category: .puzzleLogic, icon: "square.grid.3x3.fill", accentColorHex: "#7D3C98", shortDescription: "Slide tiles into order"),
        GameDefinition(id: "nonogram_solver", title: "Nonogram Solver", category: .puzzleLogic, icon: "tablecells", accentColorHex: "#1F618D", shortDescription: "Solve picture grid puzzles"),
        GameDefinition(id: "kakuro_challenge", title: "Kakuro Challenge", category: .puzzleLogic, icon: "plus.rectangle.fill", accentColorHex: "#117A65", shortDescription: "Cross-sum number puzzles"),

        GameDefinition(id: "whack_a_mole", title: "Whack-a-Mole", category: .arcadeReflex, icon: "hand.point.up.fill", accentColorHex: "#E74C3C", shortDescription: "Whack moles as they appear"),
        GameDefinition(id: "fruit_slice", title: "Fruit Slice", category: .arcadeReflex, icon: "leaf.fill", accentColorHex: "#27AE60", shortDescription: "Slice fruit avoid bombs"),
        GameDefinition(id: "target_shoot", title: "Target Shoot", category: .arcadeReflex, icon: "target", accentColorHex: "#E67E22", shortDescription: "Hit moving targets"),
        GameDefinition(id: "stack_tower", title: "Stack Tower", category: .arcadeReflex, icon: "square.stack.3d.up.fill", accentColorHex: "#3498DB", shortDescription: "Stack blocks perfectly"),
        GameDefinition(id: "rhythm_tap", title: "Rhythm Tap", category: .arcadeReflex, icon: "music.note", accentColorHex: "#9B59B6", shortDescription: "Tap to the beat"),
        GameDefinition(id: "ball_bounce", title: "Ball Bounce", category: .arcadeReflex, icon: "circle.circle.fill", accentColorHex: "#F1C40F", shortDescription: "Bounce ball into hoops"),
        GameDefinition(id: "snake_classic", title: "Snake Classic", category: .arcadeReflex, icon: "line.3.crossed.swirl.circle.fill", accentColorHex: "#2ECC71", shortDescription: "Classic snake grows longer"),
        GameDefinition(id: "pong_duel", title: "Pong Duel", category: .arcadeReflex, icon: "minus.rectangle.fill", accentColorHex: "#1ABC9C", shortDescription: "Classic pong vs AI"),

        GameDefinition(id: "othello_flip", title: "Othello Flip", category: .boardClassic, icon: "circle.lefthalf.filled", accentColorHex: "#2C3E50", shortDescription: "Classic Othello/Reversi"),
        GameDefinition(id: "go_simple", title: "Go Simple", category: .boardClassic, icon: "circle.grid.cross.fill", accentColorHex: "#34495E", shortDescription: "Simplified 9x9 Go"),
        GameDefinition(id: "battleship", title: "Battleship", category: .boardClassic, icon: "water.waves", accentColorHex: "#2980B9", shortDescription: "Find and sink ships"),
        GameDefinition(id: "dominoes", title: "Dominoes", category: .boardClassic, icon: "rectangle.split.2x1.fill", accentColorHex: "#D4AC0D", shortDescription: "Classic dominoes match"),
        GameDefinition(id: "mancala_master", title: "Mancala Master", category: .boardClassic, icon: "oval.fill", accentColorHex: "#8B4513", shortDescription: "Ancient stone game"),
        GameDefinition(id: "nine_man_morris", title: "Nine Man Morris", category: .boardClassic, icon: "circle.grid.3x3", accentColorHex: "#7D3C98", shortDescription: "Classic mill strategy"),
        GameDefinition(id: "backgammon", title: "Backgammon", category: .boardClassic, icon: "triangle.fill", accentColorHex: "#D35400", shortDescription: "Classic backgammon vs AI"),
        GameDefinition(id: "four_in_row", title: "Four in a Row", category: .boardClassic, icon: "circle.grid.2x1.fill", accentColorHex: "#E74C3C", shortDescription: "Drop discs to win"),

        GameDefinition(id: "treasure_chest", title: "Treasure Chest", category: .spinLuck, icon: "lock.fill", accentColorHex: "#D4AC0D", shortDescription: "Open chests for prizes"),
        GameDefinition(id: "lucky_pick", title: "Lucky Pick", category: .spinLuck, icon: "hand.draw.fill", accentColorHex: "#E74C3C", shortDescription: "Pick a card any card"),
        GameDefinition(id: "gem_miner", title: "Gem Miner", category: .spinLuck, icon: "diamond.fill", accentColorHex: "#3498DB", shortDescription: "Mine for hidden gems"),
        GameDefinition(id: "mystery_box", title: "Mystery Box", category: .spinLuck, icon: "shippingbox.fill", accentColorHex: "#9B59B6", shortDescription: "Open mystery boxes"),
        GameDefinition(id: "gacha_roll", title: "Gacha Roll", category: .spinLuck, icon: "sparkles", accentColorHex: "#FF69B4", shortDescription: "Collect rare characters"),
        GameDefinition(id: "crystal_ball", title: "Crystal Ball", category: .spinLuck, icon: "moon.stars.fill", accentColorHex: "#6C3483", shortDescription: "Predict outcomes for coins"),
        GameDefinition(id: "prize_claw", title: "Prize Claw", category: .spinLuck, icon: "hand.raised.fill", accentColorHex: "#F39C12", shortDescription: "Claw machine prizes"),
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
