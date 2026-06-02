import SwiftUI

struct DeveloperPluginMarketplaceView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var searchText = ""
    @State private var selectedCategory = "All"

    let categories = ["All", "Utility", "UI", "Data", "Security"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                searchAndFilter

                if filteredPlugins.isEmpty {
                    ContentUnavailableView("No Plugins Found", systemImage: "puzzlepiece.extension", description: Text("Try adjusting your search or category filter."))
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredPlugins) { plugin in
                            PluginCard(plugin: plugin)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Plugin Marketplace")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addSamplePlugin) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var searchAndFilter: some View {
        VStack(spacing: 12) {
            TextField("Search plugins...", text: $searchText)
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.blue : Color.secondary.opacity(0.1))
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var filteredPlugins: [DeveloperPlugin] {
        store.plugins.filter { plugin in
            (selectedCategory == "All" || plugin.category == selectedCategory) &&
            (searchText.isEmpty || plugin.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private func addSamplePlugin() {
        let newPlugin = DeveloperPlugin(
            name: "CloudSync Pro",
            description: "Advanced cloud synchronization for workspace assets.",
            developerID: UUID(),
            status: .published,
            category: "Data"
        )
        var updated = store.plugins
        updated.append(newPlugin)
        store.savePlugins(updated)
    }
}

private struct PluginCard: View {
    let plugin: DeveloperPlugin

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plugin.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
                Text(plugin.version)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.subheadline.bold())
                Text(plugin.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(plugin.category)
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                Spacer()
                Button("Install") {
                    // Action
                }
                .font(.caption2.bold())
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
