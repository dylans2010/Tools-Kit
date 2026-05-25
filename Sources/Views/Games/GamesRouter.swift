import SwiftUI

struct GamesRouter {
    @ViewBuilder
    static func destination(for game: GameDefinition) -> some View {
        switch game.id {
        case "battlefield_commander": BattlefieldCommanderView()
        case "warzone_strike": WarZoneStrikeView()
        case "tactical_raid": TacticalRaidView()
        case "memory_match": MemoryMatchView()
        case "sequence_recall": SequenceRecallView()
        case "number_vault": NumberVaultView()
        case "slot_machine_gold": SlotMachineGoldView()
        case "blackjack_pro": BlackjackProView()
        case "poker_nights": PokerNightsView()
        case "roulette_royal": RouletteRoyalView()
        case "dice_roll_fortune": DiceRollFortuneView()
        case "scratch_and_win": ScratchAndWinView()
        case "word_storm": WordStormView()
        case "trivia_crush": TriviaCrushView()
        case "math_blitz": MathBlitzView()
        case "sudoku_master": SudokuMasterView()
        case "minesweeper_x": MinesweeperXView()
        case "snake_ladder_classic": SnakeLadderClassicView()
        case "chess_lite": ChessLiteView()
        case "checkers_arena": CheckersArenaView()
        case "tictactoe_pro": TicTacToeProView()
        case "connect_four_blitz": ConnectFourBlitzView()
        case "bubble_pop_frenzy": BubblePopFrenzyView()
        case "tower_defense_x": TowerDefenseXView()
        case "asteroid_dodge": AsteroidDodgeView()
        case "color_rush": ColorRushView()
        case "reaction_tap": ReactionTapView()
        case "spin_wheel_prize": SpinWheelPrizeView()
        case "flip_card_duel": FlipCardDuelView()
        default: Text("Game not found").foregroundColor(.white)
        }
    }
}
