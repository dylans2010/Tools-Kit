import SwiftUI

struct GamesHomeView: View {
    @StateObject private var router = GamesRouter.shared
    @StateObject private var ledger = CurrencyLedger.shared
    @State private var searchText = ""
    @State private var selectedCategory: GameCategory?
    @State private var showingStore = false
    @State private var showingLevelUp: Int?

    var games: [GameDefinition] {
        let allGames = GameRegistry.allGames
        return allGames.filter { game in
            let matchesSearch = searchText.isEmpty || game.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || game.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var featuredGame: GameDefinition {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return GameRegistry.allGames[dayOfYear % GameRegistry.allGames.count]
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color(hex: "#0D0D1A").ignoresSafeArea()

                VStack(spacing: 0) {
                    HUDOverlayView()
                        .padding(.top)

                    ScrollView {
                        VStack(spacing: 24) {
                            GameSearchView(searchText: $searchText)

                            GameFilterBarView(selectedCategory: $selectedCategory)

                            featuredGameHeroCard

                            categoryRows

                            allGamesGrid

                            storeButton
                        }
                        .padding(.vertical)
                    }
                }

                if let level = showingLevelUp {
                    LevelUpPopupView(level: level) {
                        showingLevelUp = nil
                    }
                }
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0D0D1A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingStore) {
                CurrencyStoreView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .levelUp)) { notification in
                if let level = notification.userInfo?["level"] as? Int {
                    showingLevelUp = level
                }
            }
        }
    }

    private var featuredGameHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FEATURED GAME")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            NavigationLink(destination: featuredGame.destination) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [Color(hex: "#8A2BE2"), Color(hex: "#4B0082")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 180)
                        .shimmer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(featuredGame.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(featuredGame.category.rawValue)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        HStack {
                            Text("PERSONAL BEST: \(ledger.profile.perGameStats[featuredGame.id]?.highScore ?? 0)")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD700"))

                            Spacer()

                            Text("PLAY NOW")
                                .font(.system(.caption, design: .rounded, weight: .black))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white, in: Capsule())
                                .foregroundColor(.black)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
                .cornerRadius(20)
                .padding(.horizontal)
                .neonGlow(color: Color(hex: "#8A2BE2"))
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryRows: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(GameCategory.allCases, id: \.self) { category in
                let categoryGames = GameRegistry.allGames.filter { $0.category == category }
                if !categoryGames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(categoryGames) { game in
                                    NavigationLink(destination: game.destination) {
                                        GamingCardView(game: game, highScore: ledger.profile.perGameStats[game.id]?.highScore ?? 0)
                                            .frame(width: 160, height: 160)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    private var allGamesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL GAMES")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            GameGridView(games: games, perGameStats: ledger.profile.perGameStats)
        }
    }

    private var storeButton: some View {
        Button {
            showingStore = true
        } label: {
            HStack {
                Image(systemName: "bag.fill")
                Text("CURRENCY STORE")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#8A2BE2"), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
        .hapticTap()
    }
}

struct GameRegistry {
    static var allGames: [GameDefinition] {
        [
            GameDefinition(id: "battlefield_commander", title: "Battlefield Commander", category: .warAndBattle, iconName: "shield.fill", destination: AnyView(BattlefieldCommanderView())),
            GameDefinition(id: "warzone_strike", title: "WarZone Strike", category: .warAndBattle, iconName: "target", destination: AnyView(WarZoneStrikeView())),
            GameDefinition(id: "tactical_raid", title: "Tactical Raid", category: .warAndBattle, iconName: "bolt.fill", destination: AnyView(TacticalRaidView())),
            GameDefinition(id: "memory_match", title: "Memory Match", category: .memoryAndBrain, iconName: "brain.head.profile", destination: AnyView(MemoryMatchView())),
            GameDefinition(id: "sequence_recall", title: "Sequence Recall", category: .memoryAndBrain, iconName: "repeat", destination: AnyView(SequenceRecallView())),
            GameDefinition(id: "number_vault", title: "Number Vault", category: .memoryAndBrain, iconName: "number.square.fill", destination: AnyView(NumberVaultView())),
            GameDefinition(id: "slot_machine_gold", title: "Slot Machine Gold", category: .casinoAndGambling, iconName: "dollarsign.circle.fill", destination: AnyView(SlotMachineGoldView())),
            GameDefinition(id: "blackjack_pro", title: "Blackjack Pro", category: .casinoAndGambling, iconName: "suit.spade.fill", destination: AnyView(BlackjackProView())),
            GameDefinition(id: "poker_nights", title: "Poker Nights", category: .casinoAndGambling, iconName: "suit.heart.fill", destination: AnyView(PokerNightsView())),
            GameDefinition(id: "roulette_royal", title: "Roulette Royal", category: .casinoAndGambling, iconName: "circle.circle", destination: AnyView(RouletteRoyalView())),
            GameDefinition(id: "dice_roll_fortune", title: "Dice Roll Fortune", category: .casinoAndGambling, iconName: "die.face.5.fill", destination: AnyView(DiceRollFortuneView())),
            GameDefinition(id: "scratch_and_win", title: "Scratch & Win", category: .casinoAndGambling, iconName: "sparkles", destination: AnyView(ScratchAndWinView())),
            GameDefinition(id: "word_storm", title: "Word Storm", category: .puzzlesAndLogic, iconName: "textformat", destination: AnyView(WordStormView())),
            GameDefinition(id: "trivia_crush", title: "Trivia Crush", category: .puzzlesAndLogic, iconName: "questionmark.circle.fill", destination: AnyView(TriviaCrushView())),
            GameDefinition(id: "math_blitz", title: "Math Blitz", category: .puzzlesAndLogic, iconName: "plus.minus", destination: AnyView(MathBlitzView())),
            GameDefinition(id: "sudoku_master", title: "Sudoku Master", category: .puzzlesAndLogic, iconName: "grid", destination: AnyView(SudokuMasterView())),
            GameDefinition(id: "minesweeper_x", title: "Minesweeper X", category: .puzzlesAndLogic, iconName: "burst.fill", destination: AnyView(MinesweeperXView())),
            GameDefinition(id: "snake_ladder_classic", title: "Snake & Ladder", category: .boardAndClassic, iconName: "arrow.up.right.circle.fill", destination: AnyView(SnakeLadderClassicView())),
            GameDefinition(id: "chess_lite", title: "Chess Lite", category: .boardAndClassic, iconName: "crown.fill", destination: AnyView(ChessLiteView())),
            GameDefinition(id: "checkers_arena", title: "Checkers Arena", category: .boardAndClassic, iconName: "checkerboard.rectangle", destination: AnyView(CheckersArenaView())),
            GameDefinition(id: "tic_tac_toe_pro", title: "TicTacToe Pro", category: .boardAndClassic, iconName: "xmark.circle.fill", destination: AnyView(TicTacToeProView())),
            GameDefinition(id: "connect_four_blitz", title: "Connect Four Blitz", category: .boardAndClassic, iconName: "circle.grid.3x3.fill", destination: AnyView(ConnectFourBlitzView())),
            GameDefinition(id: "bubble_pop_frenzy", title: "Bubble Pop Frenzy", category: .arcadeAndReflex, iconName: "bubbles.and.sparkles.fill", destination: AnyView(BubblePopFrenzyView())),
            GameDefinition(id: "tower_defense_x", title: "Tower Defense X", category: .arcadeAndReflex, iconName: "shield.righthalf.filled", destination: AnyView(TowerDefenseXView())),
            GameDefinition(id: "asteroid_dodge", title: "Asteroid Dodge", category: .arcadeAndReflex, iconName: "airplane", destination: AnyView(AsteroidDodgeView())),
            GameDefinition(id: "color_rush", title: "Color Rush", category: .arcadeAndReflex, iconName: "paintpalette.fill", destination: AnyView(ColorRushView())),
            GameDefinition(id: "reaction_tap", title: "Reaction Tap", category: .arcadeAndReflex, iconName: "hand.tap.fill", destination: AnyView(ReactionTapView())),
            GameDefinition(id: "flip_card_duel", title: "Flip Card Duel", category: .spinAndLuck, iconName: "rectangle.portrait.on.rectangle.portrait.fill", destination: AnyView(FlipCardDuelView())),
            GameDefinition(id: "spin_wheel_prize", title: "Spin Wheel Prize", category: .spinAndLuck, iconName: "circle.dotted", destination: AnyView(SpinWheelPrizeView()))
        ]
    }
}
