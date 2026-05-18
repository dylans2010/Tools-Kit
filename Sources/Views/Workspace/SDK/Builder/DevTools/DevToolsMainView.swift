import SwiftUI

struct DevToolsMainView: View {
    @StateObject private var registry = DevToolRegistry.shared
    @State private var searchText = ""
    @State private var expandedCategories: Set<String> = Set(DevToolCategory.allCases.map(\.rawValue))

    private var filteredTools: [AnyDevTool] {
        registry.search(searchText)
    }

    private var groupedTools: [(DevToolCategory, [AnyDevTool])] {
        let tools = filteredTools
        return DevToolCategory.allCases.compactMap { category in
            let categoryTools = tools.filter { $0.category == category }
            return categoryTools.isEmpty ? nil : (category, categoryTools)
        }
    }

    var body: some View {
        List {
            toolSummarySection
            ForEach(groupedTools, id: \.0) { category, tools in
                categorySection(category: category, tools: tools)
            }
        }
        .searchable(text: $searchText, prompt: "Search tools...")
        .navigationTitle("Dev Tools")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { expandAll() } label: { Label("Expand All", systemImage: "arrow.up.left.and.arrow.down.right") }
                    Button { collapseAll() } label: { Label("Collapse All", systemImage: "arrow.down.right.and.arrow.up.left") }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }

    // MARK: - Summary

    private var toolSummarySection: some View {
        Section {
            HStack {
                Label("\(registry.tools.count) Tools", systemImage: "wrench.and.screwdriver.fill")
                    .font(.headline)
                Spacer()
                Text("\(registry.categoriesWithTools.count) Categories")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !searchText.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("\(filteredTools.count) results for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(category: DevToolCategory, tools: [AnyDevTool]) -> some View {
        Section(isExpanded: Binding(
            get: { expandedCategories.contains(category.rawValue) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category.rawValue)
                } else {
                    expandedCategories.remove(category.rawValue)
                }
            }
        )) {
            ForEach(tools) { tool in
                NavigationLink(destination: tool.render()) {
                    HStack(spacing: 12) {
                        Image(systemName: tool.icon)
                            .font(.title3)
                            .foregroundStyle(.accent)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.name)
                                .font(.subheadline.weight(.medium))
                            Text(tool.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            HStack {
                Image(systemName: category.icon)
                Text(category.rawValue)
                Spacer()
                Text("\(tools.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Helpers

    private func expandAll() {
        expandedCategories = Set(DevToolCategory.allCases.map(\.rawValue))
    }

    private func collapseAll() {
        expandedCategories.removeAll()
    }
}
