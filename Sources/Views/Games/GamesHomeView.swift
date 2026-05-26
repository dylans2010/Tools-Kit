import SwiftUI

struct GamesHomeView: View {
    @StateObject private var ledger = CurrencyLedger.shared
    @StateObject private var xpEngine = XPEngine.shared
    @State private var searchText = ""
    @State private var selectedCategory: GameCategory?
    @State private var showStore = false
    @State private var showSettings = false
    @State private var showDailyBonus = false
    @State private var dailyBonusResult: (coins: Int, gems: Int)?

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
                mainContent

                if xpEngine.didLevelUp {
                    LevelUpPopupView(level: xpEngine.newLevel, bonusCoins: xpEngine.bonusCoinsAwarded) { xpEngine.clearLevelUp() }
                }
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showStore) { NavigationStack { CurrencyStoreView() } }
            .fullScreenCover(isPresented: $showSettings) {
                AIChatSettingsView(settings: AIChatSettingsManager.shared.settingsBinding)
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                HUDOverlayView(ledger: ledger, xpEngine: xpEngine)

                if ledger.profile.isDailyBonusAvailable {
                    dailyBonusBanner
                }

                if ledger.profile.dailyStreak > 1 {
                    streakBanner
                }

                playerStatsSummary

                GameSearchView(searchText: $searchText)
                GameFilterBarView(selectedCategory: $selectedCategory)

                if searchText.isEmpty && selectedCategory == nil {
                    featuredCard
                }

                if selectedCategory != nil || !searchText.isEmpty {
                    resultsGrid
                } else {
                    categorizedLists
                }

                storeButton
            }
        }
    }

    private var resultsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filteredGames) { game in
                let highScore = ledger.highScore(for: game.id)
                NavigationLink { GamesRouter.destination(for: game) } label: {
                    GamingCardView(game: game, highScore: highScore)
                }
            }
        }.padding(.horizontal)
    }

    private var categorizedLists: some View {
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
                            let highScore = ledger.highScore(for: game.id)
                            NavigationLink { GamesRouter.destination(for: game) } label: {
                                GamingCardView(game: game, highScore: highScore)
                                    .frame(width: 160)
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }

    private var storeButton: some View {
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

    private var dailyBonusBanner: some View {
        Button {
            let result = ledger.collectDailyBonus()
            if result.coins > 0 || result.gems > 0 {
                dailyBonusResult = result
                showDailyBonus = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showDailyBonus = false }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill").font(.title2).foregroundColor(GamingDesignTokens.accentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Bonus Available!").font(.headline.bold()).foregroundColor(.white)
                    let streakDays = min(ledger.profile.dailyStreak, 7)
                    Text("Day \(max(streakDays, 1)) streak bonus • Tap to collect").font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(GamingDesignTokens.accentGold)
            }
            .padding()
            .background(
                LinearGradient(colors: [GamingDesignTokens.accentGold.opacity(0.3), GamingDesignTokens.accentPurple.opacity(0.3)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(GamingDesignTokens.accentGold.opacity(0.5), lineWidth: 1))
        }
        .padding(.horizontal)
        .overlay {
            if showDailyBonus, let result = dailyBonusResult {
                VStack(spacing: 4) {
                    Text("+\(result.coins) coins").font(.headline.bold()).foregroundColor(GamingDesignTokens.accentGold)
                    if result.gems > 0 { Text("+\(result.gems) gem").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentPurple) }
                }
                .padding(12)
                .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showDailyBonus)
    }

    private var streakBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill").foregroundColor(GamingDesignTokens.dangerRed)
            Text("\(ledger.profile.dailyStreak)-day streak").font(.subheadline.bold()).foregroundColor(.white)
            Spacer()
            Text("\(Int((ledger.dailyStreakMultiplier() - 1) * 100))% bonus").font(.caption.bold()).foregroundColor(GamingDesignTokens.accentNeon)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private var playerStatsSummary: some View {
        HStack(spacing: 0) {
            statItem(icon: "gamecontroller.fill", value: "\(ledger.profile.gamesPlayed)", label: "Played")
            statItem(icon: "trophy.fill", value: "\(ledger.profile.totalWins)", label: "Wins")
            statItem(icon: "percent", value: String(format: "%.0f%%", ledger.profile.winRate), label: "Win Rate")
            statItem(icon: "star.fill", value: "\(ledger.profile.unlockedBadges.count)", label: "Badges")
        }
        .padding(.vertical, 10)
        .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(GamingDesignTokens.accentNeon)
            Text(value).font(.system(.subheadline, design: .monospaced).bold()).foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
        }.frame(maxWidth: .infinity)
    }

    private var featuredCard: some View {
        NavigationLink { GamesRouter.destination(for: featuredGame) } label: {
            ZStack {
                LinearGradient(colors: [GamingDesignTokens.accentPurple, GamingDesignTokens.accentNeon.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shimmer()

                VStack(alignment: .leading, spacing: 8) {
                    featuredHeader
                    Spacer()
                    Text(featuredGame.title).font(.title2.bold()).foregroundColor(.white)
                    featuredFooter
                }.padding()
            }.padding(.horizontal)
        }
    }

    private var featuredHeader: some View {
        HStack {
            Text("FEATURED").font(.caption.bold()).foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.white.opacity(0.2), in: Capsule())
            Spacer()
            Text(featuredGame.category.label).font(.caption).foregroundColor(.white.opacity(0.6))
        }
    }

    private var featuredFooter: some View {
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
    }
}
