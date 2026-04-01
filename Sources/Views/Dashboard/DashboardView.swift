import SwiftUI

struct DashboardView: View {
    @StateObject private var registry = ToolRegistry()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SearchBar(text: $searchText)

                    if searchText.isEmpty {
                        recentlyUsedSection
                        favoritesSection
                        basicToolsSection
                        advancedToolsSection
                    } else {
                        searchResultsSection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            }
            .navigationTitle("Tools Kit")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var recentlyUsedSection: some View {
        let recent = registry.tools.filter { registry.recentlyUsedIDs.contains($0.id) }
        return Group {
            if !recent.isEmpty {
                VStack(alignment: .leading) {
                    SectionHeader(title: "Recently Used", subtitle: "Quick access to your last tools", icon: "clock.arrow.circlepath")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
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
                        HStack(spacing: 16) {
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
                HStack(spacing: 16) {
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
                HStack(spacing: 16) {
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

    private var searchResultsSection: some View {
        let results = registry.filteredTools(query: searchText)
        return VStack(alignment: .leading) {
            SectionHeader(title: "Search Results", subtitle: "Found \(results.count) tools", icon: "magnifyingglass")
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
