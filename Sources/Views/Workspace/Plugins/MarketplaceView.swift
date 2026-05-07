import SwiftUI

struct MarketplaceView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: PluginCapability?

    private var filteredPlugins: [PluginDefinition] {
        manager.availablePlugins.filter { plugin in
            let matchesSearch = searchText.isEmpty ||
                               plugin.name.localizedCaseInsensitiveContains(searchText) ||
                               plugin.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                                 plugin.capabilities.contains(selectedCategory!)
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    StatusIndicator(label: "Available", count: manager.availablePlugins.count, color: .blue)
                    StatusIndicator(label: "Installed", count: manager.installedPlugins.count, color: .green)
                    StatusIndicator(label: "Trending", count: 12, color: .orange)
                }
                .padding(.vertical, 8)
            }

            Section("Categories") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(PluginCapability.allCases) { cap in
                            FilterChip(title: cap.displayName, isSelected: selectedCategory == cap) {
                                selectedCategory = cap
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Projects (Built with WorkspaceSDK)") {
                // Mock projects for now as real ones come from WorkspaceSDK runtime
                NavigationLink(destination: Text("Project Detail")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("CRM Plus").font(.headline)
                            Text("Advanced customer management").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        MadeForWorkspaceBadge()
                    }
                }
            }

            Section("Discover Plugins") {
                if filteredPlugins.isEmpty {
                    Text("No Plugins Found").foregroundColor(.secondary).font(.subheadline)
                } else {
                    ForEach(filteredPlugins) { plugin in
                        NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                            MarketplacePluginRow(plugin: plugin)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Marketplace")
        .navigationTitle("Marketplace")
    }
}

struct MarketplacePluginRow: View {
    let plugin: PluginDefinition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: plugin.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(plugin.name).font(.subheadline).bold()
                    if plugin.isInstalled {
                        Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
                    }
                    Spacer()
                    MadeForWorkspaceBadge()
                }
                Text(plugin.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                HStack {
                    Text("v\(plugin.version)").font(.caption2).foregroundStyle(.tertiary)
                    Text("·").font(.caption2).foregroundStyle(.tertiary)
                    Text(plugin.author).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MadeForWorkspaceBadge: View {
    var body: some View {
        Text("Made For Workspace")
            .font(.system(size: 8, weight: .bold))
            .padding(4)
            .background(Color.purple.opacity(0.1))
            .foregroundColor(.purple)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
    }
}
