import SwiftUI

struct GamesHomeView: View {
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
    @State private var searchText = ""
    @State private var selectedCategory: GameCategory?
    @State private var showStore = false

    private var featuredGame: GameDefinition {
        GameDefinition.featuredGame()
    }

    private var filteredGames: [GameDefinition] {
        var games = GameDefinition.allGames
        if let cat = selectedCategory {
            games = games.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            games = games.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.shortDescription.localizedCaseInsensitiveContains(searchText) }
        }
        return games
    }

    private var gamesByCategory: [(GameCategory, [GameDefinition])] {
        let categories = GameCategory.allCases
        return categories.compactMap { cat in
            let games = filteredGames.filter { $0.category == cat }
            return games.isEmpty ? nil : (cat, games)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GamingDesignTokens.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HUDOverlayView(ledger: ledger, xpEngine: xpEngine)

                        GameSearchView(searchText: $searchText)
                        GameFilterBarView(selectedCategory: $selectedCategory)

                        if searchText.isEmpty && selectedCategory == nil {
                            featuredCard
                        }

                        if selectedCategory != nil || !searchText.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(filteredGames) { game in
                                    NavigationLink { GamesRouter.destination(for: game) } label: { GamingCardView(game: game, ledger: ledger) }
                                }
                            }.padding(.horizontal)
                        } else {
                            ForEach(gamesByCategory, id: \.0) { cat, games in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: cat.icon).foregroundColor(GamingDesignTokens.accentNeon)
                                        Text(cat.label).font(.headline.bold()).foregroundColor(.white)
                                        Spacer()
                                    }.padding(.horizontal)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(games) { game in
                                                NavigationLink { GamesRouter.destination(for: game) } label: { GamingCardView(game: game, ledger: ledger).frame(width: 160) }
                                            }
                                        }.padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Button { showStore = true } label: {
                            HStack {
                                Image(systemName: "bag.fill").foregroundColor(GamingDesignTokens.accentGold)
                                Text("Currency Store").font(.headline).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
                            }
                            .padding()
                            .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                        }.padding(.horizontal).padding(.bottom, 20)
                    }
                }

                if xpEngine.didLevelUp {
                    LevelUpPopupView(level: xpEngine.newLevel, bonusCoins: xpEngine.bonusCoinsAwarded) { xpEngine.clearLevelUp() }
                }
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showStore) { NavigationStack { CurrencyStoreView() } }
        }
    }

    private var featuredCard: some View {
        NavigationLink { GamesRouter.destination(for: featuredGame) } label: {
            ZStack {
                LinearGradient(colors: [GamingDesignTokens.accentPurple, GamingDesignTokens.accentNeon.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shimmer()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("FEATURED").font(.caption.bold()).foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.white.opacity(0.2), in: Capsule())
                        Spacer()
                        Text(featuredGame.category.label).font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text(featuredGame.title).font(.title2.bold()).foregroundColor(.white)
                    HStack {
                        Image(systemName: featuredGame.icon).foregroundColor(.white)
                        Text(featuredGame.shortDescription).font(.subheadline).foregroundColor(.white.opacity(0.8))
                        Spacer()
                        let highScore = ledger.highScore(for: featuredGame.id)
                        if highScore > 0 {
                            Text("High: \(highScore)").font(.caption.bold().monospacedDigit()).foregroundColor(GamingDesignTokens.accentGold)
                        }
                        Image(systemName: "play.fill").foregroundColor(.white).font(.title3)
                            .padding(8).background(Color.white.opacity(0.2), in: Circle())
                    }
                }.padding()
            }.padding(.horizontal)
        }
    }
}
