import SwiftUI

struct DashboardView: View {
    @StateObject private var registry = ToolRegistry()
    @StateObject private var visibility = ToolVisibilityManager.shared
    @StateObject private var settingsManager = AIChatSettingsManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ToolCategory? = nil
    @State private var showSettings = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dashboardHeader
                    SearchBar(text: $searchText)
                    categoryPicker

                    if searchText.isEmpty && selectedCategory == nil {
                        toolSection(title: "Favorites", tools: favoriteTools)
                        toolSection(title: "Recently Used", tools: recentTools)
                        toolSection(title: "All Tools", tools: visibleTools)
                    } else {
                        let filtered = registry.filteredTools(query: searchText, category: selectedCategory)
                            .filter { visibility.isVisible($0.id) }
                        toolSection(title: "Results", tools: filtered)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tools Kit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                AIChatSettingsView(settings: $settingsManager.settings)
            }
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose your tool")
                .font(.title.bold())
            Text("\(visibleTools.count) of \(registry.tools.count) tools across \(ToolCategory.allCases.count) categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
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

    private var visibleTools: [any Tool] {
        registry.tools.filter { visibility.isVisible($0.id) }
    }

    private var favoriteTools: [any Tool] {
        visibleTools.filter { registry.favoriteToolIDs.contains($0.id) }
    }

    private var recentTools: [any Tool] {
        visibleTools.filter { registry.recentlyUsedIDs.contains($0.id) }
    }

    @ViewBuilder
    private func toolSection(title: String, tools: [any Tool]) -> some View {
        if !tools.isEmpty {
            SectionHeader(title: title, subtitle: "\(tools.count) tools", icon: "square.grid.2x2")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(tools, id: \.id) { tool in
                    NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                        ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                            registry.toggleFavorite(toolID: tool.id)
                        }
                    }
                    .buttonStyle(.plain)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(18)
        }
    }
}
