import SwiftUI

struct DashboardView: View {
    @StateObject private var registry = ToolRegistry()
    @State private var searchText = ""
    @State private var selectedCategory: ToolCategory? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SearchBar(text: $searchText)

                    categoryPicker

                    if searchText.isEmpty && selectedCategory == nil {
                        weatherSection
                        recentlyUsedSection
                        favoritesSection
                        basicToolsSection
                        advancedToolsSection
                    } else {
                        filteredResultsSection
                    }
                }
            }
            .navigationTitle("Tools Kit")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryTag(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(ToolCategory.allCases, id: \.self) { category in
                    CategoryTag(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var weatherSection: some View {
        NavigationLink(destination: WeatherView()) {
            WeatherMiniCard()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var recentlyUsedSection: some View {
        let recent = registry.tools.filter { registry.recentlyUsedIDs.contains($0.id) }
        return Group {
            if !recent.isEmpty {
                VStack(alignment: .leading) {
                    SectionHeader(title: "Recently Used", subtitle: "Quick access to your last tools", icon: "clock.arrow.circlepath")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(recent, id: \.id) { tool in
                                NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                                    ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                                        registry.toggleFavorite(toolID: tool.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        let favorites = registry.tools.filter { registry.favoriteToolIDs.contains($0.id) }
        return Group {
            if !favorites.isEmpty {
                VStack(alignment: .leading) {
                    SectionHeader(title: "Favorites", subtitle: "Your pinned tools", icon: "star.fill")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(favorites, id: \.id) { tool in
                                NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                                    ToolCard(tool: tool, isFavorite: true) {
                                        registry.toggleFavorite(toolID: tool.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private var basicToolsSection: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: "Basic Tools", subtitle: "Everyday fast-access utilities", icon: "briefcase")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(registry.basicTools, id: \.id) { tool in
                        NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                            ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                                registry.toggleFavorite(toolID: tool.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private var advancedToolsSection: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: "Advanced Tools", subtitle: "Power user and developer utilities", icon: "cpu")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(registry.advancedTools, id: \.id) { tool in
                        NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                            ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                                registry.toggleFavorite(toolID: tool.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private var filteredResultsSection: some View {
        let results = registry.filteredTools(query: searchText, category: selectedCategory)
        return VStack(alignment: .leading) {
            SectionHeader(title: "Filtered Tools", subtitle: "Found \(results.count) tools", icon: "line.3.horizontal.decrease.circle")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(results, id: \.id) { tool in
                    NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                        ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                            registry.toggleFavorite(toolID: tool.id)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
